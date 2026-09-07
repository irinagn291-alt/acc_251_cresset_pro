import Foundation

/// Role: Wake. Remainder after TileMarks spend ten pages each. Token does not walk on Wake.
struct Wake: Equatable, Sendable {
    var pages: Double

    var canStep: Bool {
        pages >= Isle.pagesPerTile
    }
}
