import Foundation

/// Role: Isle. In-memory harbor for previews and tests. Views never see this type.
actor HarborHold: HarborStoring {
    private var latest: Archipelago
    private var warning: HarborWarning?

    init(board: Archipelago = .empty, warning: HarborWarning? = nil) {
        self.latest = board
        self.warning = warning
    }

    func load() async -> (board: Archipelago, warning: HarborWarning?) {
        (latest, warning)
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
        return latest
    }

    func logSitting(
        isleID: UUID,
        minutes: Double,
        now: Date,
        calendar: Calendar
    ) async throws -> Archipelago {
        latest = try latest.logging(isleID: isleID, minutes: minutes, now: now, calendar: calendar)
        return latest
    }

    func stepToken(
        isleID: UUID,
        now: Date,
        calendar: Calendar
    ) async throws -> Archipelago {
        latest = try latest.stepping(isleID: isleID, now: now, calendar: calendar)
        return latest
    }

    func setOnboardingComplete(_ flag: Bool) async -> Archipelago {
        latest.onboardingComplete = flag
        return latest
    }

    func flush() async throws {}

    func resetAllData() async throws {
        latest = .empty
        warning = nil
    }

    func seedDemoIfNeeded(now: Date, calendar: Calendar) async throws -> Archipelago? {
        nil
    }
}
