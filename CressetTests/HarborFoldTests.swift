import XCTest
@testable import Cresset

final class HarborFoldTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        utc.locale = Locale(identifier: "en_US_POSIX")
        calendar = utc
    }

    func test_familyInvariant_tenPagesPerTileEightTilesAndLampOnFirstReach() throws {
        let totalTiles = Isle.totalTiles
        XCTAssertEqual(totalTiles, 8)
        XCTAssertEqual(Isle.pagesPerTile, 10)

        let minutes = 40.0
        let pace = 0.5
        let pagesFromMinutesTimesPace = Isle.pages(minutes: minutes, pace: pace)
        XCTAssertEqual(pagesFromMinutesTimesPace, minutes * pace)

        let totalPages = 25.0
        let tile = min(Int(totalPages / 10.0), totalTiles - 1)
        XCTAssertEqual(Isle.tileIndex(totalPages: totalPages), tile)
        XCTAssertEqual(Isle.tileIndex(totalPages: 0), 0)
        XCTAssertEqual(Isle.tileIndex(totalPages: 80), 7)
        XCTAssertEqual(Isle.tileIndex(markCount: 8), min(8, totalTiles - 1))

        var isle = Isle.vacant(drift: .fable)
        let volume = try Volume.drafted(title: "Salt", pageCount: 200, drift: .fable, pace: pace)
        isle = try isle.mooring(volume)
        isle = try isle.logging(minutes: minutes, now: instant(2026, 9, 1), calendar: calendar)
        XCTAssertEqual(isle.wake.pages, 20)
        XCTAssertEqual(isle.tileIndex, 0)
        XCTAssertNil(isle.lamp)
        XCTAssertFalse(isle.ringUnlocked)

        isle = try isle.stepping(now: instant(2026, 9, 1), calendar: calendar)
        XCTAssertNotNil(isle.lamp)
        XCTAssertTrue(isle.ringUnlocked)
        XCTAssertEqual(isle.marks.count, 1)
        XCTAssertEqual(isle.tileIndex, min(1, totalTiles - 1))
        XCTAssertEqual(isle.wake.pages, 10)
    }

    func test_architectureFold_poolingSteppedLit() throws {
        var isle = Isle.vacant(drift: .lyric)
        XCTAssertEqual(isle.fold, .pooling(wake: 0))

        let volume = try Volume.drafted(title: "Hymns", pageCount: 80, drift: .lyric, pace: 0.5)
        isle = try isle.mooring(volume)
        isle = try isle.logging(minutes: 30, now: instant(2026, 9, 2), calendar: calendar)
        XCTAssertEqual(isle.fold, .pooling(wake: 15))

        var stepped = isle
        stepped.marks = [
            TileMark(id: UUID(), index: 1, day: DayStamp(rawValue: 20260902), steppedUnix: 0),
        ]
        XCTAssertEqual(stepped.fold, .stepped(wake: 5, marks: 1))

        isle = try isle.stepping(now: instant(2026, 9, 2), calendar: calendar)
        XCTAssertEqual(isle.fold, .lit(wake: 5, marks: 1))
        isle = try isle.logging(minutes: 30, now: instant(2026, 9, 2), calendar: calendar)
        isle = try isle.stepping(now: instant(2026, 9, 2), calendar: calendar)
        XCTAssertEqual(isle.fold, .lit(wake: 10, marks: 2))
    }

    func test_primaryVerb_emptyPopulatedInvalid() throws {
        var isle = Isle.vacant(drift: .voyage)
        XCTAssertThrowsError(try isle.stepping(now: instant(2026, 9, 3), calendar: calendar)) { error in
            XCTAssertEqual(error as? HarborFault, .wakeTooShallow)
        }
        XCTAssertThrowsError(try isle.logging(minutes: 20, now: instant(2026, 9, 3), calendar: calendar)) { error in
            XCTAssertEqual(error as? HarborFault, .noMooredVolume)
        }

        let volume = try Volume.drafted(title: "Reach", pageCount: 120, drift: .voyage, pace: 0.5)
        isle = try isle.mooring(volume)
        XCTAssertThrowsError(try isle.logging(minutes: 0, now: instant(2026, 9, 3), calendar: calendar)) { error in
            XCTAssertEqual(error as? HarborFault, .invalidMinutes)
        }
        XCTAssertThrowsError(try isle.logging(minutes: -4, now: instant(2026, 9, 3), calendar: calendar)) { error in
            XCTAssertEqual(error as? HarborFault, .invalidMinutes)
        }

        isle = try isle.logging(minutes: 24, now: instant(2026, 9, 3), calendar: calendar)
        XCTAssertTrue(isle.canStep)
        isle = try isle.stepping(now: instant(2026, 9, 3), calendar: calendar)
        XCTAssertEqual(isle.marks.count, 1)
        XCTAssertEqual(isle.wake.pages, 2)
        XCTAssertFalse(isle.canStep)

        XCTAssertThrowsError(try Volume.drafted(title: "   ", pageCount: 10, drift: .fable, pace: 1)) { error in
            XCTAssertEqual(error as? HarborFault, .emptyTitle)
        }
        XCTAssertThrowsError(try Volume.drafted(title: "Ok", pageCount: 0, drift: .fable, pace: 1)) { error in
            XCTAssertEqual(error as? HarborFault, .invalidPageCount)
        }
        XCTAssertThrowsError(try Volume.drafted(title: "Ok", pageCount: 10, drift: .fable, pace: 0)) { error in
            XCTAssertEqual(error as? HarborFault, .invalidPace)
        }
    }

    func test_twist_logFillsWakeStepSpendsTenAndWalksOneTile() throws {
        var isle = Isle.vacant(drift: .chronicle)
        let volume = try Volume.drafted(title: "Keel", pageCount: 300, drift: .chronicle, pace: 0.5)
        isle = try isle.mooring(volume)
        isle = try isle.logging(minutes: 18, now: instant(2026, 9, 4), calendar: calendar)
        XCTAssertEqual(isle.wake.pages, 9)
        XCTAssertEqual(isle.marks.count, 0)
        XCTAssertEqual(isle.tileIndex, 0)
        XCTAssertEqual(isle.fold, .pooling(wake: 9))

        isle = try isle.logging(minutes: 10, now: instant(2026, 9, 4), calendar: calendar)
        XCTAssertEqual(isle.wake.pages, 14)
        XCTAssertEqual(isle.marks.count, 0)
        XCTAssertEqual(isle.tileIndex, 0)

        isle = try isle.stepping(now: instant(2026, 9, 4), calendar: calendar)
        XCTAssertEqual(isle.wake.pages, 4)
        XCTAssertEqual(isle.marks.count, 1)
        XCTAssertEqual(isle.marks[0].index, 1)
        XCTAssertEqual(isle.tileIndex, 1)
        XCTAssertNotNil(isle.lamp)
    }

    func test_ringStopsAtEightMarks() throws {
        var isle = Isle.vacant(drift: .hearth)
        let volume = try Volume.drafted(title: "Hearth", pageCount: 90, drift: .hearth, pace: 1)
        isle = try isle.mooring(volume)
        isle = try isle.logging(minutes: 90, now: instant(2026, 9, 5), calendar: calendar)
        for _ in 0 ..< Isle.totalTiles {
            isle = try isle.stepping(now: instant(2026, 9, 5), calendar: calendar)
        }
        XCTAssertEqual(isle.marks.count, 8)
        XCTAssertEqual(isle.tileIndex, Isle.totalTiles - 1)
        XCTAssertThrowsError(try isle.stepping(now: instant(2026, 9, 5), calendar: calendar)) { error in
            XCTAssertEqual(error as? HarborFault, .ringComplete)
        }
    }

    func test_seedLeavesStepEnabledAndLightsALamp() {
        let board = HarborSeed.board(now: instant(2026, 9, 3), calendar: calendar)
        XCTAssertTrue(board.onboardingComplete)
        XCTAssertGreaterThanOrEqual(board.isles.count, 3)
        XCTAssertGreaterThanOrEqual(board.lampCount, 1)
        XCTAssertTrue(board.canStep)
        let fable = board.isle(for: .fable)
        XCTAssertGreaterThanOrEqual(fable?.wake.pages ?? 0, Isle.pagesPerTile)
        XCTAssertEqual(fable?.fold, .lit(wake: fable?.wake.pages ?? 0, marks: fable?.marks.count ?? 0))
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
