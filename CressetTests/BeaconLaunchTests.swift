import XCTest
@testable import Cresset

final class BeaconLaunchTests: XCTestCase {
    func test_readsOnceAfterOnboarding() {
        var consumed = false
        XCTAssertNil(
            BeaconLaunch.consume(
                arguments: ["-ReviewScreen", "log"],
                onboardingComplete: false,
                consumed: &consumed
            )
        )
        XCTAssertFalse(consumed)

        let first = BeaconLaunch.consume(
            arguments: ["app", "-ReviewScreen", "log"],
            onboardingComplete: true,
            consumed: &consumed
        )
        XCTAssertEqual(first, .log)
        XCTAssertEqual(first?.tab, .analytics)
        XCTAssertTrue(consumed)
        XCTAssertNil(
            BeaconLaunch.consume(
                arguments: ["-ReviewScreen", "goals"],
                onboardingComplete: true,
                consumed: &consumed
            )
        )
    }

    func test_threeKeysAreDistinctScreens() {
        XCTAssertEqual(BeaconPane.today.rawValue, "today")
        XCTAssertEqual(BeaconPane.log.rawValue, "log")
        XCTAssertEqual(BeaconPane.goals.rawValue, "goals")
        XCTAssertNotEqual(BeaconPane.today, BeaconPane.log)
        XCTAssertNotEqual(BeaconPane.log, BeaconPane.goals)
        XCTAssertNotEqual(BeaconPane.today, BeaconPane.goals)
        XCTAssertEqual(BeaconPane.today.tab, .board)
        XCTAssertEqual(BeaconPane.log.tab, .analytics)
        XCTAssertEqual(BeaconPane.goals.tab, .settings)
        XCTAssertNotEqual(BeaconPane.today.tab, BeaconPane.log.tab)
        XCTAssertNotEqual(BeaconPane.log.tab, BeaconPane.goals.tab)

        var consumed = false
        XCTAssertEqual(
            BeaconLaunch.consume(
                arguments: ["-ReviewScreen", "today"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .today
        )
        consumed = false
        XCTAssertEqual(
            BeaconLaunch.consume(
                arguments: ["-ReviewScreen", "goals"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .goals
        )
    }

    func test_unknownKeyIsIgnored() {
        var consumed = false
        XCTAssertNil(
            BeaconLaunch.consume(
                arguments: ["-ReviewScreen", "aura"],
                onboardingComplete: true,
                consumed: &consumed
            )
        )
        XCTAssertTrue(consumed)
    }
}
