import Foundation

/// Role: Isle. Preference keys. Snapshot is JSON Data under crs.store.v1. Demo is Simulator-only.
enum HarborKey {
    static let snapshot = "crs.store.v1"
    static let backup = "crs.store.v1.backup"
    static let demo = "crs.demo.v1"
}

/// Role: Isle. Recoverable load outcome. Never crash on a corrupt snapshot.
enum HarborWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedEmpty
}

/// Role: Isle. The only persistence seam. Views observe the board; they never touch UserDefaults or files.
protocol HarborStoring: Sendable {
    func load() async -> (board: Archipelago, warning: HarborWarning?)
    func snapshot() async -> Archipelago
    func placeVolume(
        title: String,
        pageCount: Int,
        drift: Drift,
        pace: Double
    ) async throws -> Archipelago
    func logSitting(isleID: UUID, minutes: Double, now: Date, calendar: Calendar) async throws -> Archipelago
    func stepToken(isleID: UUID, now: Date, calendar: Calendar) async throws -> Archipelago
    func setOnboardingComplete(_ flag: Bool) async -> Archipelago
    func flush() async throws
    func resetAllData() async throws
    func seedDemoIfNeeded(now: Date, calendar: Calendar) async throws -> Archipelago?
}

/// Role: Isle. Memory is the source of truth. UserDefaults crs.store.v1 plus an Application Support file are projections.
actor HarborStore: HarborStoring {
    private let directory: URL
    private let defaultsSuiteName: String?
    private let fileManager: FileManager
    private let writeDelayNanoseconds: UInt64

    private var latest: Archipelago = .empty
    private var dirty = false
    private var writeTask: Task<Void, Never>?
    private(set) var warning: HarborWarning?
    private(set) var lastWriteError: String?

    init(
        directory: URL,
        defaultsSuiteName: String? = nil,
        fileManager: FileManager = .default,
        writeDelayNanoseconds: UInt64 = 300_000_000
    ) {
        self.directory = directory
        self.defaultsSuiteName = defaultsSuiteName
        self.fileManager = fileManager
        self.writeDelayNanoseconds = writeDelayNanoseconds
    }

    static func applicationSupportDirectory(fileManager: FileManager = .default) throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("Cresset", isDirectory: true)
    }

    func load() async -> (board: Archipelago, warning: HarborWarning?) {
        warning = nil
        latest = .empty
        dirty = false
        let defaults = preferenceDefaults()
        if let data = defaults.data(forKey: HarborKey.snapshot), let board = decode(data) {
            latest = board
            return (latest, nil)
        }
        if let board = decodeFile(fileURL) {
            latest = board
            return (latest, nil)
        }
        if let data = defaults.data(forKey: HarborKey.backup), let board = decode(data) {
            latest = board
            warning = .recoveredFromBackup
            return (latest, warning)
        }
        if let board = decodeFile(backupURL) {
            latest = board
            warning = .recoveredFromBackup
            return (latest, warning)
        }
        let hadPayload = defaults.data(forKey: HarborKey.snapshot) != nil
            || fileManager.fileExists(atPath: fileURL.path)
        if hadPayload {
            warning = .startedEmpty
        }
        return (latest, warning)
    }

    func snapshot() async -> Archipelago {
        latest
    }

    func placeVolume(
        title: String,
        pageCount: Int,
        drift: Drift,
        pace: Double
    ) async throws -> Archipelago {
        let volume = try Volume.drafted(title: title, pageCount: pageCount, drift: drift, pace: pace)
        latest = try latest.placing(volume)
        try persistCommitted()
        return latest
    }

    func logSitting(
        isleID: UUID,
        minutes: Double,
        now: Date = Date(),
        calendar: Calendar = .current
    ) async throws -> Archipelago {
        latest = try latest.logging(isleID: isleID, minutes: minutes, now: now, calendar: calendar)
        try persistCommitted()
        return latest
    }

    func stepToken(
        isleID: UUID,
        now: Date = Date(),
        calendar: Calendar = .current
    ) async throws -> Archipelago {
        latest = try latest.stepping(isleID: isleID, now: now, calendar: calendar)
        try persistCommitted()
        return latest
    }

    func setOnboardingComplete(_ flag: Bool) async -> Archipelago {
        latest.onboardingComplete = flag
        dirty = true
        scheduleFlush()
        return latest
    }

    func flush() async throws {
        writeTask?.cancel()
        writeTask = nil
        if dirty {
            try persistCommitted()
        }
    }

    func resetAllData() async throws {
        writeTask?.cancel()
        writeTask = nil
        latest = .empty
        dirty = false
        warning = nil
        lastWriteError = nil
        let defaults = preferenceDefaults()
        defaults.removeObject(forKey: HarborKey.snapshot)
        defaults.removeObject(forKey: HarborKey.backup)
        defaults.removeObject(forKey: HarborKey.demo)
        if fileManager.fileExists(atPath: directory.path) {
            try fileManager.removeItem(at: directory)
        }
        prepareDirectory()
    }

    func seedDemoIfNeeded(now: Date = Date(), calendar: Calendar = .current) async throws -> Archipelago? {
        #if targetEnvironment(simulator)
        let defaults = preferenceDefaults()
        guard defaults.object(forKey: HarborKey.demo) == nil else { return nil }
        latest = HarborSeed.board(now: now, calendar: calendar)
        try persistCommitted()
        defaults.set(true, forKey: HarborKey.demo)
        return latest
        #else
        return nil
        #endif
    }

    private func persistCommitted() throws {
        let ledger = HarborLedger.committed(from: latest)
        let data = try HarborCodec.encode(ledger)
        let defaults = preferenceDefaults()
        if let previous = defaults.data(forKey: HarborKey.snapshot) {
            defaults.set(previous, forKey: HarborKey.backup)
        }
        defaults.set(data, forKey: HarborKey.snapshot)
        prepareDirectory()
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: backupURL)
            try? fileManager.copyItem(at: fileURL, to: backupURL)
        }
        try data.write(to: fileURL, options: .atomic)
        dirty = false
        lastWriteError = nil
    }

    private func scheduleFlush() {
        writeTask?.cancel()
        let delay = writeDelayNanoseconds
        writeTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.flushIfNeeded()
        }
    }

    private func flushIfNeeded() async {
        writeTask = nil
        do {
            if dirty {
                try persistCommitted()
            }
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    private func decode(_ data: Data) -> Archipelago? {
        guard let ledger = try? HarborCodec.decode(data) else { return nil }
        return ledger.asBoard()
    }

    private func decodeFile(_ url: URL) -> Archipelago? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return decode(data)
    }

    private var fileURL: URL {
        directory.appendingPathComponent("harbor.json")
    }

    private var backupURL: URL {
        directory.appendingPathComponent("harbor.json.backup")
    }

    private func preferenceDefaults() -> UserDefaults {
        if let defaultsSuiteName {
            return UserDefaults(suiteName: defaultsSuiteName) ?? .standard
        }
        return .standard
    }

    private func prepareDirectory() {
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }
}
