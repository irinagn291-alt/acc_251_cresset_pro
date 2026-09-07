import Foundation

/// Role: Isle. Codable root document. schemaVersion from 1. Domain types never encode themselves.
struct HarborLedger: Equatable, Sendable {
    var schemaVersion: Int
    var onboardingComplete: Bool
    var isles: [Isle]

    static func committed(from board: Archipelago) -> HarborLedger {
        HarborLedger(
            schemaVersion: HarborCodec.currentSchema,
            onboardingComplete: board.onboardingComplete,
            isles: board.isles
        )
    }

    func asBoard() -> Archipelago {
        Archipelago(isles: isles, onboardingComplete: onboardingComplete)
    }
}

/// Role: Isle. schemaVersion switch and board ↔ JSON mapping. UserDefaults never sees Isle raw.
enum HarborCodec {
    static let currentSchema = 1

    enum Failure: Error, Equatable {
        case unsupportedSchema(Int)
        case corrupt
    }

    static func encode(_ ledger: HarborLedger) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(RootDocument.from(ledger))
    }

    static func decode(_ data: Data) throws -> HarborLedger {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw Failure.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                return try decoder.decode(RootDocument.self, from: data).asLedger()
            } catch let failure as Failure {
                throw failure
            } catch {
                throw Failure.corrupt
            }
        default:
            throw Failure.unsupportedSchema(probe.schemaVersion)
        }
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}

private struct RootDocument: Codable {
    var schemaVersion: Int
    var onboardingComplete: Bool
    var isles: [IsleDocument]

    static func from(_ ledger: HarborLedger) -> RootDocument {
        RootDocument(
            schemaVersion: HarborCodec.currentSchema,
            onboardingComplete: ledger.onboardingComplete,
            isles: ledger.isles.map(IsleDocument.init(isle:))
        )
    }

    func asLedger() throws -> HarborLedger {
        HarborLedger(
            schemaVersion: schemaVersion,
            onboardingComplete: onboardingComplete,
            isles: try isles.map { try $0.asIsle() }
        )
    }
}

private struct IsleDocument: Codable {
    var id: UUID
    var drift: String
    var volumes: [VolumeDocument]
    var mooredID: UUID?
    var sittings: [SittingDocument]
    var marks: [MarkDocument]
    var lampDay: Int?
    var lampUnix: Double?

    init(isle: Isle) {
        id = isle.id
        drift = isle.drift.rawValue
        volumes = isle.volumes.map(VolumeDocument.init(volume:))
        mooredID = isle.mooredID
        sittings = isle.sittings.map(SittingDocument.init(sitting:))
        marks = isle.marks.map(MarkDocument.init(mark:))
        lampDay = isle.lamp?.day.rawValue
        lampUnix = isle.lamp?.litUnix
    }

    func asIsle() throws -> Isle {
        guard let drift = Drift(rawValue: drift) else { throw HarborCodec.Failure.corrupt }
        let lamp: Lamp?
        if let lampDay, let lampUnix {
            lamp = Lamp(day: DayStamp(rawValue: lampDay), litUnix: lampUnix)
        } else {
            lamp = nil
        }
        return Isle(
            id: id,
            drift: drift,
            volumes: try volumes.map { try $0.asVolume() },
            mooredID: mooredID,
            sittings: sittings.map { $0.asSitting() },
            marks: marks.map { $0.asMark() },
            lamp: lamp
        )
    }
}

private struct VolumeDocument: Codable {
    var id: UUID
    var title: String
    var pageCount: Int
    var drift: String
    var pace: Double

    init(volume: Volume) {
        id = volume.id
        title = volume.title
        pageCount = volume.pageCount
        drift = volume.drift.rawValue
        pace = volume.pace
    }

    func asVolume() throws -> Volume {
        guard let drift = Drift(rawValue: drift) else { throw HarborCodec.Failure.corrupt }
        return Volume(id: id, title: title, pageCount: pageCount, drift: drift, pace: pace)
    }
}

private struct SittingDocument: Codable {
    var id: UUID
    var volumeID: UUID
    var minutes: Double
    var pace: Double
    var day: Int
    var loggedUnix: Double

    init(sitting: Sitting) {
        id = sitting.id
        volumeID = sitting.volumeID
        minutes = sitting.minutes
        pace = sitting.pace
        day = sitting.day.rawValue
        loggedUnix = sitting.loggedUnix
    }

    func asSitting() -> Sitting {
        Sitting(
            id: id,
            volumeID: volumeID,
            minutes: minutes,
            pace: pace,
            day: DayStamp(rawValue: day),
            loggedUnix: loggedUnix
        )
    }
}

private struct MarkDocument: Codable {
    var id: UUID
    var index: Int
    var day: Int
    var steppedUnix: Double

    init(mark: TileMark) {
        id = mark.id
        index = mark.index
        day = mark.day.rawValue
        steppedUnix = mark.steppedUnix
    }

    func asMark() -> TileMark {
        TileMark(
            id: id,
            index: index,
            day: DayStamp(rawValue: day),
            steppedUnix: steppedUnix
        )
    }
}
