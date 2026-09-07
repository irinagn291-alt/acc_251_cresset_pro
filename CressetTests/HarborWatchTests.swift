import XCTest
@testable import Cresset

@MainActor
final class HarborWatchTests: XCTestCase {
    func test_seededHomeEnablesStepAndNamesTheJob() {
        let watch = HarborWatch.previewPopulated()
        XCTAssertTrue(watch.board.onboardingComplete)
        XCTAssertTrue(watch.canStep)
        XCTAssertEqual(watch.jobTitle, "Step the token")
        XCTAssertTrue(watch.jobLine.contains("Tap Step"))
        XCTAssertGreaterThanOrEqual(watch.wakeFill, 1)
        XCTAssertGreaterThanOrEqual(watch.focused?.wake.pages ?? 0, Isle.pagesPerTile)
        XCTAssertEqual(watch.tab, .board)
    }

    func test_emptyPopulatedErrorStates() {
        XCTAssertTrue(HarborWatch.previewEmpty().isEmpty)
        XCTAssertFalse(HarborWatch.previewEmpty().loadFailed)
        XCTAssertFalse(HarborWatch.previewPopulated().isEmpty)
        XCTAssertTrue(HarborWatch.previewError().loadFailed)
        XCTAssertEqual(HarborWatch.previewError().warning, .startedEmpty)
    }

    func test_stepSpendsTenAndWalksOneTile() async {
        let board = HarborSeed.board()
        let watch = HarborWatch(
            store: HarborHold(board: board),
            board: board,
            shouldLoad: false
        )
        let beforeWake = watch.focused?.wake.pages ?? 0
        let beforeMarks = watch.focused?.marks.count ?? 0
        XCTAssertTrue(watch.canStep)
        await watch.stepToken()
        XCTAssertNil(watch.fault)
        XCTAssertEqual(watch.focused?.marks.count, beforeMarks + 1)
        XCTAssertEqual((watch.focused?.wake.pages ?? 0), beforeWake - Isle.pagesPerTile, accuracy: 0.001)
        XCTAssertEqual(watch.steppedTick, 1)
        XCTAssertEqual(watch.commitTick, 1)
    }

    func test_logFillsWakeWithoutWalking() async throws {
        var isle = Isle.vacant(drift: .tract)
        let volume = try Volume.drafted(title: "Tract", pageCount: 80, drift: .tract, pace: 0.5)
        isle = try isle.mooring(volume)
        let board = Archipelago(isles: [isle], onboardingComplete: true)
        let watch = HarborWatch(
            store: HarborHold(board: board),
            board: board,
            shouldLoad: false
        )
        await watch.logSitting(minutes: 12)
        XCTAssertEqual(watch.focused?.wake.pages, 6)
        XCTAssertEqual(watch.focused?.marks.count, 0)
        XCTAssertFalse(watch.canStep)
        XCTAssertEqual(watch.commitTick, 1)
        await watch.logSitting(minutes: 0)
        XCTAssertEqual(watch.fault, "Minutes must be greater than zero.")
        XCTAssertEqual(watch.focused?.wake.pages, 6)
    }

    func test_reviewHookSelectsAnalyticsAfterOnboarding() {
        let watch = HarborWatch.previewPopulated()
        watch.applyReview(arguments: ["-ReviewScreen", "log"])
        XCTAssertEqual(watch.tab, .analytics)
        watch.applyReview(arguments: ["-ReviewScreen", "goals"])
        XCTAssertEqual(watch.tab, .analytics)
    }
}
