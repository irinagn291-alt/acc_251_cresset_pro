import Foundation

/// Role: Wake. One logged watch of minutes. Pages equal minutes times the pace frozen here.
struct Sitting: Identifiable, Equatable, Sendable {
    var id: UUID
    var volumeID: UUID
    var minutes: Double
    var pace: Double
    var day: DayStamp
    var loggedUnix: TimeInterval

    var pages: Double {
        Isle.pages(minutes: minutes, pace: pace)
    }
}
