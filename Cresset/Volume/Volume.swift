import Foundation

/// Role: Volume. A book moored on a drift isle. Pace is pages per minute at log time.
struct Volume: Identifiable, Equatable, Sendable {
    var id: UUID
    var title: String
    var pageCount: Int
    var drift: Drift
    var pace: Double

    static func drafted(
        id: UUID = UUID(),
        title: String,
        pageCount: Int,
        drift: Drift,
        pace: Double
    ) throws -> Volume {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw HarborFault.emptyTitle }
        guard pageCount > 0 else { throw HarborFault.invalidPageCount }
        guard pace.isFinite, pace > 0 else { throw HarborFault.invalidPace }
        return Volume(id: id, title: trimmed, pageCount: pageCount, drift: drift, pace: pace)
    }
}
