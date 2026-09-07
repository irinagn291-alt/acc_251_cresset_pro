import Foundation
import Observation

/// Role: Isle. Presentation fold over HarborStoring. Views observe this; they never touch UserDefaults or Isle mutation.
@MainActor
@Observable
final class HarborWatch {
    private(set) var board: Archipelago
    private(set) var warning: HarborWarning?
    private(set) var fault: String?
    private(set) var isHauling = false
    private(set) var isCommitting = false
    private(set) var steppedTick = 0
    private(set) var commitTick = 0
    private(set) var dayAnchor: Date

    var tab: HarborTab = .board
    var focusedID: UUID?

    let store: any HarborStoring
    private let calendar: Calendar
    private let now: () -> Date
    private let shouldLoad: Bool
    private var appeared = false
    private var reviewConsumed = false
    private var haulToken: UUID?

    init(
        store: any HarborStoring,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() },
        board: Archipelago = .empty,
        warning: HarborWarning? = nil,
        shouldLoad: Bool = true
    ) {
        self.store = store
        self.calendar = calendar
        self.now = now
        self.board = board
        self.warning = warning
        self.shouldLoad = shouldLoad
        self.dayAnchor = calendar.startOfDay(for: now())
    }

    var focused: Isle? {
        if let focusedID, let isle = board.isle(id: focusedID) {
            return isle
        }
        return board.isles.first(where: \.canStep) ?? board.isles.first
    }

    var canStep: Bool {
        focused?.canStep ?? false
    }

    var isEmpty: Bool {
        board.isles.isEmpty
    }

    var loadFailed: Bool {
        warning == .startedEmpty && board.isles.isEmpty
    }

    var recovered: Bool {
        warning == .recoveredFromBackup
    }

    var jobTitle: String {
        guard let isle = focused else { return "Place a book" }
        if isle.canStep { return "Step the token" }
        if isle.moored != nil { return "Fill the wake" }
        return "Place a book"
    }

    var jobLine: String {
        guard let isle = focused else {
            return "Tap empty water and moor a volume on its genre isle."
        }
        if isle.canStep {
            return "Wake holds \(LampFigure.pages(isle.wake.pages)) pages. Tap Step to walk one tile."
        }
        if isle.moored != nil {
            return "Log minutes. Pages equal minutes times pace. Step when Wake holds ten."
        }
        return "Moor a volume on this isle, then log minutes."
    }

    var wakeFill: Double {
        guard let pages = focused?.wake.pages else { return 0 }
        return min(1, max(0, pages / Isle.pagesPerTile))
    }

    var stepDetail: String {
        guard let isle = focused else {
            return "Place a book, then log minutes until Wake holds ten pages."
        }
        if isle.canStep {
            return "Spend ten pages. Walk one tile."
        }
        if isle.marks.count >= Isle.totalTiles {
            return "This isle already walked all eight tiles."
        }
        let need = max(0, Isle.pagesPerTile - isle.wake.pages)
        return "Need \(LampFigure.pages(need)) more pages in Wake."
    }

    func previewPages(minutes: Double) -> Double {
        guard let pace = focused?.moored?.pace else { return 0 }
        return Isle.pages(minutes: minutes, pace: pace)
    }

    func volumeTitle(id: UUID) -> String {
        for isle in board.isles {
            if let volume = isle.volumes.first(where: { $0.id == id }) {
                return volume.title
            }
        }
        return "—"
    }

    func sittingsNewestFirst() -> [Sitting] {
        board.isles.flatMap(\.sittings).sorted { $0.loggedUnix > $1.loggedUnix }
    }

    func marksNewestFirst() -> [TileMark] {
        board.isles.flatMap(\.marks).sorted { $0.steppedUnix > $1.steppedUnix }
    }

    func isle(for mark: TileMark) -> Isle? {
        board.isles.first { isle in
            isle.marks.contains(where: { $0.id == mark.id })
        }
    }

    func appear() async {
        guard shouldLoad else {
            focusDefault()
            applyReview()
            return
        }
        if appeared {
            applyReview()
            return
        }
        appeared = true
        let token = UUID()
        haulToken = token
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard let self, self.haulToken == token else { return }
            self.isHauling = true
        }
        let loaded = await store.load()
        board = loaded.board
        warning = loaded.warning
        do {
            if let seeded = try await store.seedDemoIfNeeded(now: now(), calendar: calendar) {
                board = seeded
                warning = nil
            }
        } catch {
            fault = "The harbor could not be opened."
        }
        applyWarning()
        focusDefault()
        applyReview()
        haulToken = nil
        isHauling = false
    }

    func retry() async {
        fault = nil
        appeared = false
        await appear()
    }

    func flush() async {
        do {
            try await store.flush()
        } catch {
            fault = "The harbor could not be written."
        }
    }

    func markDay() {
        dayAnchor = calendar.startOfDay(for: now())
    }

    func focus(_ id: UUID) {
        focusedID = id
    }

    func placeVolume(title: String, pageCount: Int, drift: Drift, pace: Double) async {
        await run {
            self.board = try await self.store.placeVolume(
                title: title,
                pageCount: pageCount,
                drift: drift,
                pace: pace
            )
            self.focusedID = self.board.isle(for: drift)?.id
            self.commitTick += 1
        }
    }

    func logSitting(minutes: Double) async {
        guard let isle = focused else {
            fault = Self.copy(.unknownIsle)
            return
        }
        await run {
            self.board = try await self.store.logSitting(
                isleID: isle.id,
                minutes: minutes,
                now: self.now(),
                calendar: self.calendar
            )
            self.commitTick += 1
        }
    }

    func stepToken() async {
        guard let isle = focused else {
            fault = Self.copy(.unknownIsle)
            return
        }
        await run {
            self.board = try await self.store.stepToken(
                isleID: isle.id,
                now: self.now(),
                calendar: self.calendar
            )
            self.steppedTick += 1
            self.commitTick += 1
        }
    }

    func finishOnboarding(skipped: Bool) async {
        board = await store.setOnboardingComplete(true)
        do {
            try await store.flush()
        } catch {
            fault = "The harbor could not be written."
        }
        applyReview()
        _ = skipped
    }

    func reopenOnboarding() async {
        board = await store.setOnboardingComplete(false)
    }

    func resetAll() async {
        await run {
            try await self.store.resetAllData()
            self.board = .empty
            self.warning = nil
            self.focusedID = nil
            self.tab = .board
        }
    }

    func applyReview(arguments: [String] = ProcessInfo.processInfo.arguments) {
        if let pane = BeaconLaunch.consume(
            arguments: arguments,
            onboardingComplete: board.onboardingComplete,
            consumed: &reviewConsumed
        ) {
            tab = pane.tab
        }
    }

    static func live() -> HarborWatch {
        let directory: URL
        do {
            directory = try HarborStore.applicationSupportDirectory()
        } catch {
            directory = FileManager.default.temporaryDirectory.appendingPathComponent(
                "Cresset",
                isDirectory: true
            )
        }
        return HarborWatch(store: HarborStore(directory: directory))
    }

    static func previewPopulated() -> HarborWatch {
        let board = HarborSeed.board()
        return HarborWatch(
            store: HarborHold(board: board),
            board: board,
            shouldLoad: false
        )
    }

    static func previewEmpty() -> HarborWatch {
        var board = Archipelago.empty
        board.onboardingComplete = true
        return HarborWatch(
            store: HarborHold(board: board),
            board: board,
            shouldLoad: false
        )
    }

    static func previewError() -> HarborWatch {
        var board = Archipelago.empty
        board.onboardingComplete = true
        return HarborWatch(
            store: HarborHold(board: board, warning: .startedEmpty),
            board: board,
            warning: .startedEmpty,
            shouldLoad: false
        )
    }

    private func focusDefault() {
        if let focusedID, board.isle(id: focusedID) != nil {
            return
        }
        focusedID = board.isles.first(where: \.canStep)?.id ?? board.isles.first?.id
    }

    private func applyWarning() {
        if warning == .startedEmpty, board.isles.isEmpty {
            fault = "The harbor could not be read. The water is empty."
        } else if warning == .recoveredFromBackup {
            fault = "Recovered the last good harbor."
        }
    }

    private func run(_ work: () async throws -> Void) async {
        guard !isCommitting else { return }
        isCommitting = true
        defer { isCommitting = false }
        do {
            fault = nil
            try await work()
            focusDefault()
        } catch let harbor as HarborFault {
            fault = Self.copy(harbor)
        } catch {
            fault = "Something went wrong. Try again."
        }
    }

    private static func copy(_ fault: HarborFault) -> String {
        switch fault {
        case .emptyTitle:
            "Give the volume a title."
        case .invalidPageCount:
            "Page count must be greater than zero."
        case .invalidPace:
            "Pace must be greater than zero."
        case .invalidMinutes:
            "Minutes must be greater than zero."
        case .driftMismatch:
            "That volume belongs on a different isle."
        case .noMooredVolume:
            "Place a volume before logging minutes."
        case .wakeTooShallow:
            "Wake needs ten pages before a step."
        case .ringComplete:
            "This isle already walked all eight tiles."
        case .unknownIsle:
            "That isle is no longer on the board."
        }
    }
}

/// Role: Isle. Fold captions for the board chrome. Views never switch on wake math.
extension HarborFold {
    var caption: String {
        switch self {
        case .pooling:
            "Wake filling"
        case .stepped:
            "Walking tiles"
        case .lit:
            "Lamp lit"
        }
    }
}
