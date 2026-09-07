import Foundation

/// Role: Isle. Typed faults of place, log, and step. Views map these; they never mutate Isle.
enum HarborFault: Error, Equatable, Sendable {
    case emptyTitle
    case invalidPageCount
    case invalidPace
    case invalidMinutes
    case driftMismatch
    case noMooredVolume
    case wakeTooShallow
    case ringComplete
    case unknownIsle
}

/// Role: Isle. Wake ADT fold: Pooling | Stepped | Lit. Step writes a TileMark and spends ten.
enum HarborFold: Equatable, Sendable {
    case pooling(wake: Double)
    case stepped(wake: Double, marks: Int)
    case lit(wake: Double, marks: Int)

    static func folding(wake: Double, marks: Int, lampLit: Bool) -> HarborFold {
        if lampLit {
            return .lit(wake: wake, marks: marks)
        }
        if marks > 0 {
            return .stepped(wake: wake, marks: marks)
        }
        return .pooling(wake: wake)
    }
}

/// Role: Isle. One drift island. Fold over sittings into Wake; Step walks a tile and may write the Lamp.
struct Isle: Identifiable, Equatable, Sendable {
    static let pagesPerTile = 10.0
    static let totalTiles = 8

    var id: UUID
    var drift: Drift
    var volumes: [Volume]
    var mooredID: UUID?
    var sittings: [Sitting]
    var marks: [TileMark]
    var lamp: Lamp?

    static func vacant(id: UUID = UUID(), drift: Drift) -> Isle {
        Isle(
            id: id,
            drift: drift,
            volumes: [],
            mooredID: nil,
            sittings: [],
            marks: [],
            lamp: nil
        )
    }

    static func pages(minutes: Double, pace: Double) -> Double {
        max(0, minutes) * max(0, pace)
    }

    static func tileIndex(totalPages: Double) -> Int {
        min(Int(totalPages / pagesPerTile), totalTiles - 1)
    }

    static func tileIndex(markCount: Int) -> Int {
        min(max(markCount, 0), totalTiles - 1)
    }

    var moored: Volume? {
        guard let mooredID else { return nil }
        return volumes.first(where: { $0.id == mooredID })
    }

    var earnedPages: Double {
        sittings.reduce(0) { $0 + $1.pages }
    }

    var wake: Wake {
        let remainder = earnedPages - Double(marks.count) * Self.pagesPerTile
        return Wake(pages: max(0, remainder))
    }

    var tileIndex: Int {
        Self.tileIndex(markCount: marks.count)
    }

    var fold: HarborFold {
        HarborFold.folding(wake: wake.pages, marks: marks.count, lampLit: lamp != nil)
    }

    var canStep: Bool {
        wake.canStep && marks.count < Self.totalTiles
    }

    var ringUnlocked: Bool {
        lamp != nil
    }

    func mooring(_ volume: Volume) throws -> Isle {
        guard volume.drift == drift else { throw HarborFault.driftMismatch }
        var next = self
        if !next.volumes.contains(where: { $0.id == volume.id }) {
            next.volumes.append(volume)
        }
        next.mooredID = volume.id
        return next
    }

    func logging(
        minutes: Double,
        now: Date,
        calendar: Calendar,
        sittingID: UUID = UUID()
    ) throws -> Isle {
        guard minutes.isFinite, minutes > 0 else { throw HarborFault.invalidMinutes }
        guard let volume = moored else { throw HarborFault.noMooredVolume }
        var next = self
        next.sittings.append(
            Sitting(
                id: sittingID,
                volumeID: volume.id,
                minutes: minutes,
                pace: volume.pace,
                day: DayStamp.from(now, calendar: calendar),
                loggedUnix: now.timeIntervalSince1970
            )
        )
        return next
    }

    func stepping(
        now: Date,
        calendar: Calendar,
        markID: UUID = UUID()
    ) throws -> Isle {
        guard marks.count < Self.totalTiles else { throw HarborFault.ringComplete }
        guard wake.canStep else { throw HarborFault.wakeTooShallow }
        var next = self
        let count = next.marks.count + 1
        next.marks.append(
            TileMark(
                id: markID,
                index: Self.tileIndex(markCount: count),
                day: DayStamp.from(now, calendar: calendar),
                steppedUnix: now.timeIntervalSince1970
            )
        )
        if next.lamp == nil {
            next.lamp = Lamp(
                day: DayStamp.from(now, calendar: calendar),
                litUnix: now.timeIntervalSince1970
            )
        }
        return next
    }
}
