import Foundation

/// Role: Isle. The board of drift isles. Place and session fold here; views never touch storage.
struct Archipelago: Equatable, Sendable {
    var isles: [Isle]
    var onboardingComplete: Bool

    static let empty = Archipelago(isles: [], onboardingComplete: false)

    var tileMarkCount: Int {
        isles.reduce(0) { $0 + $1.marks.count }
    }

    var lampCount: Int {
        isles.reduce(0) { $0 + ($1.lamp == nil ? 0 : 1) }
    }

    var canStep: Bool {
        isles.contains(where: \.canStep)
    }

    func isle(id: UUID) -> Isle? {
        isles.first(where: { $0.id == id })
    }

    func isle(for drift: Drift) -> Isle? {
        isles.first(where: { $0.drift == drift })
    }

    func placing(_ volume: Volume, isleID: UUID = UUID()) throws -> Archipelago {
        var next = self
        if let index = next.isles.firstIndex(where: { $0.drift == volume.drift }) {
            next.isles[index] = try next.isles[index].mooring(volume)
        } else {
            let vacant = Isle.vacant(id: isleID, drift: volume.drift)
            next.isles.append(try vacant.mooring(volume))
        }
        return next
    }

    func logging(
        isleID: UUID,
        minutes: Double,
        now: Date,
        calendar: Calendar,
        sittingID: UUID = UUID()
    ) throws -> Archipelago {
        var next = self
        guard let index = next.isles.firstIndex(where: { $0.id == isleID }) else {
            throw HarborFault.unknownIsle
        }
        next.isles[index] = try next.isles[index].logging(
            minutes: minutes,
            now: now,
            calendar: calendar,
            sittingID: sittingID
        )
        return next
    }

    func stepping(
        isleID: UUID,
        now: Date,
        calendar: Calendar,
        markID: UUID = UUID()
    ) throws -> Archipelago {
        var next = self
        guard let index = next.isles.firstIndex(where: { $0.id == isleID }) else {
            throw HarborFault.unknownIsle
        }
        next.isles[index] = try next.isles[index].stepping(
            now: now,
            calendar: calendar,
            markID: markID
        )
        return next
    }
}
