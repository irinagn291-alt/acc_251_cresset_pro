import Foundation

/// Role: Isle. Board, Analytics, Settings. ReviewScreen today|log|goals maps onto these tabs.
enum HarborTab: String, Hashable, Sendable {
    case board
    case analytics
    case settings
}

/// Role: Isle. Launch keys for live shots. Read once, only after onboarding.
enum BeaconPane: String, Equatable, Sendable {
    case today
    case log
    case goals

    var tab: HarborTab {
        switch self {
        case .today: .board
        case .log: .analytics
        case .goals: .settings
        }
    }
}

/// Role: Isle. `-ReviewScreen today|log|goals` via ProcessInfo. Hook never fires during onboarding.
enum BeaconLaunch {
    static func consume(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        onboardingComplete: Bool,
        consumed: inout Bool
    ) -> BeaconPane? {
        guard onboardingComplete, !consumed else { return nil }
        consumed = true
        guard let index = arguments.firstIndex(of: "-ReviewScreen") else { return nil }
        let next = arguments.index(after: index)
        guard arguments.indices.contains(next) else { return nil }
        return BeaconPane(rawValue: arguments[next])
    }
}
