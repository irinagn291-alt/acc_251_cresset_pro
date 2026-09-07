import XCTest
@testable import Cresset

final class HarborStoreTests: XCTestCase {
    private var directory: URL!
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var calendar: Calendar!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        suiteName = "crs.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        utc.locale = Locale(identifier: "en_US_POSIX")
        calendar = utc
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        directory = nil
        defaults = nil
        suiteName = nil
    }

    func test_roundTrip_reloadPreservesWakeMarksAndLamp() async throws {
        let store = makeStore()
        let now = instant(2026, 9, 3)
        let placed = try await store.placeVolume(title: "Salt Atlas", pageCount: 200, drift: .fable, pace: 0.5)
        let isleID = try XCTUnwrap(placed.isles.first?.id)
        _ = try await store.logSitting(isleID: isleID, minutes: 30, now: now, calendar: calendar)
        let stepped = try await store.stepToken(isleID: isleID, now: now, calendar: calendar)
        XCTAssertEqual(stepped.isles.first?.marks.count, 1)
        XCTAssertNotNil(stepped.isles.first?.lamp)
        XCTAssertEqual(stepped.isles.first?.wake.pages, 5)

        let relaunched = makeStore()
        let loaded = await relaunched.load()
        XCTAssertNil(loaded.warning)
        XCTAssertEqual(loaded.board.isles.first?.id, isleID)
        XCTAssertEqual(loaded.board.isles.first?.moored?.title, "Salt Atlas")
        XCTAssertEqual(loaded.board.isles.first?.marks.count, 1)
        XCTAssertNotNil(loaded.board.isles.first?.lamp)
        XCTAssertEqual(loaded.board.isles.first?.wake.pages, 5)
        XCTAssertEqual(loaded.board.isles.first?.sittings.first?.day.rawValue, 20260903)
    }

    func test_corruptSnapshotFallsBackToBackup() async throws {
        let store = makeStore()
        _ = try await store.placeVolume(title: "Hymns", pageCount: 80, drift: .lyric, pace: 0.4)
        if let good = defaults.data(forKey: HarborKey.snapshot) {
            defaults.set(good, forKey: HarborKey.backup)
        }
        let file = directory.appendingPathComponent("harbor.json")
        let backup = directory.appendingPathComponent("harbor.json.backup")
        if FileManager.default.fileExists(atPath: file.path) {
            try? FileManager.default.removeItem(at: backup)
            try FileManager.default.copyItem(at: file, to: backup)
        }
        defaults.set(Data("{not-json".utf8), forKey: HarborKey.snapshot)
        try Data("{not-json".utf8).write(to: file)

        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.warning, .recoveredFromBackup)
        XCTAssertEqual(loaded.board.isles.first?.moored?.title, "Hymns")
    }

    func test_corruptSnapshotWithoutBackupStartsEmpty() async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defaults.set(Data("nope".utf8), forKey: HarborKey.snapshot)
        try Data("nope".utf8).write(to: directory.appendingPathComponent("harbor.json"))
        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.warning, .startedEmpty)
        XCTAssertTrue(loaded.board.isles.isEmpty)
    }

    func test_codecSwitchesOnSchemaVersion() throws {
        let board = HarborSeed.board(now: instant(2026, 9, 3), calendar: calendar)
        let ledger = HarborLedger.committed(from: board)
        let data = try HarborCodec.encode(ledger)
        let decoded = try HarborCodec.decode(data)
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.isles.count, board.isles.count)
        XCTAssertEqual(decoded.isles.first?.moored?.title, "The Salt Atlas")

        let future = Data("{\"schemaVersion\":99}".utf8)
        XCTAssertThrowsError(try HarborCodec.decode(future)) { error in
            XCTAssertEqual(error as? HarborCodec.Failure, .unsupportedSchema(99))
        }
        XCTAssertThrowsError(try HarborCodec.decode(Data("[]".utf8))) { error in
            XCTAssertEqual(error as? HarborCodec.Failure, .corrupt)
        }
    }

    func test_resetAllDataClearsSnapshotAndFiles() async throws {
        let store = makeStore()
        _ = try await store.placeVolume(title: "Keel", pageCount: 40, drift: .chronicle, pace: 0.5)
        try await store.resetAllData()
        let loaded = await store.load()
        XCTAssertTrue(loaded.board.isles.isEmpty)
        XCTAssertNil(defaults.data(forKey: HarborKey.snapshot))
        XCTAssertNil(defaults.data(forKey: HarborKey.backup))
        let leftovers = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        XCTAssertTrue(leftovers.filter { $0.pathExtension == "json" }.isEmpty)
    }

    func test_onboardingFlagDebouncesUntilFlush() async throws {
        let store = makeStore()
        _ = try await store.placeVolume(title: "Reach", pageCount: 50, drift: .voyage, pace: 0.5)
        _ = await store.setOnboardingComplete(true)
        try await store.flush()
        let loaded = await makeStore().load()
        XCTAssertTrue(loaded.board.onboardingComplete)
    }

    #if targetEnvironment(simulator)
    func test_simulatorSeedWritesOnceAndEnablesStep() async throws {
        let store = makeStore()
        let now = instant(2026, 9, 3)
        let first = try await store.seedDemoIfNeeded(now: now, calendar: calendar)
        let second = try await store.seedDemoIfNeeded(now: now, calendar: calendar)
        XCTAssertNil(second)
        XCTAssertEqual(first?.onboardingComplete, true)
        XCTAssertEqual(first?.canStep, true)
        XCTAssertGreaterThanOrEqual(first?.lampCount ?? 0, 1)
        XCTAssertGreaterThanOrEqual(first?.isles.count ?? 0, 3)
        XCTAssertTrue(defaults.bool(forKey: HarborKey.demo))
        XCTAssertNotNil(defaults.data(forKey: HarborKey.snapshot))
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("harbor.json").path))
    }
    #endif

    private func makeStore() -> HarborStore {
        HarborStore(
            directory: directory,
            defaultsSuiteName: suiteName,
            writeDelayNanoseconds: 0
        )
    }

    private func instant(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        parts.hour = 12
        return calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
    }
}
