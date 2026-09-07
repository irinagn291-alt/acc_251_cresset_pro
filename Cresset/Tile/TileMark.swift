import Foundation

/// Role: Tile. One spent step. Index is min(mark count, totalTiles minus one).
struct TileMark: Identifiable, Equatable, Sendable {
    var id: UUID
    var index: Int
    var day: DayStamp
    var steppedUnix: TimeInterval
}
