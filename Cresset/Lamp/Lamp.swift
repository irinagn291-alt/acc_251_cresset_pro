import Foundation

/// Role: Lamp. Written on the first TileMark. Later steps stay Lit.
struct Lamp: Equatable, Sendable {
    var day: DayStamp
    var litUnix: TimeInterval
}
