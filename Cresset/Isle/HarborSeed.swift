import Foundation

/// Role: Isle. Simulator demo archipelago. Device never writes this. Key: crs.demo.v1.
enum HarborSeed {
    private static func fixed(_ value: String) -> UUID {
        UUID(uuidString: value) ?? UUID()
    }

    static func board(now: Date = Date(), calendar: Calendar = .current) -> Archipelago {
        let today = DayStamp.from(now, calendar: calendar)
        let unix = now.timeIntervalSince1970

        let atlas = Volume(
            id: fixed("A1B2C3D4-E5F6-7890-ABCD-EF1234567890"),
            title: "The Salt Atlas",
            pageCount: 312,
            drift: .fable,
            pace: 0.5
        )
        let hymns = Volume(
            id: fixed("B2C3D4E5-F6A7-8901-BCDE-F12345678901"),
            title: "Harbor Hymns",
            pageCount: 148,
            drift: .lyric,
            pace: 0.4
        )
        let keels = Volume(
            id: fixed("C3D4E5F6-A7B8-9012-CDEF-123456789012"),
            title: "Keel Chronicle",
            pageCount: 420,
            drift: .chronicle,
            pace: 0.6
        )
        let reach = Volume(
            id: fixed("D4E5F6A7-B8C9-0123-DEF0-234567890123"),
            title: "Westward Reach",
            pageCount: 276,
            drift: .voyage,
            pace: 0.5
        )

        let fable = Isle(
            id: fixed("11111111-1111-1111-1111-111111111111"),
            drift: .fable,
            volumes: [atlas],
            mooredID: atlas.id,
            sittings: [
                Sitting(
                    id: fixed("11111111-0000-0000-0000-000000000001"),
                    volumeID: atlas.id,
                    minutes: 40,
                    pace: atlas.pace,
                    day: today,
                    loggedUnix: unix - 7_200
                ),
                Sitting(
                    id: fixed("11111111-0000-0000-0000-000000000002"),
                    volumeID: atlas.id,
                    minutes: 30,
                    pace: atlas.pace,
                    day: today,
                    loggedUnix: unix - 3_600
                ),
            ],
            marks: [
                TileMark(
                    id: fixed("11111111-AAAA-0000-0000-000000000001"),
                    index: 1,
                    day: today,
                    steppedUnix: unix - 5_400
                ),
                TileMark(
                    id: fixed("11111111-AAAA-0000-0000-000000000002"),
                    index: 2,
                    day: today,
                    steppedUnix: unix - 1_800
                ),
            ],
            lamp: Lamp(day: today, litUnix: unix - 5_400)
        )

        let lyric = Isle(
            id: fixed("22222222-2222-2222-2222-222222222222"),
            drift: .lyric,
            volumes: [hymns],
            mooredID: hymns.id,
            sittings: [
                Sitting(
                    id: fixed("22222222-0000-0000-0000-000000000001"),
                    volumeID: hymns.id,
                    minutes: 35,
                    pace: hymns.pace,
                    day: today,
                    loggedUnix: unix - 86_400
                ),
            ],
            marks: [
                TileMark(
                    id: fixed("22222222-AAAA-0000-0000-000000000001"),
                    index: 1,
                    day: today,
                    steppedUnix: unix - 80_000
                ),
            ],
            lamp: Lamp(day: today, litUnix: unix - 80_000)
        )

        let chronicle = Isle(
            id: fixed("33333333-3333-3333-3333-333333333333"),
            drift: .chronicle,
            volumes: [keels],
            mooredID: keels.id,
            sittings: [
                Sitting(
                    id: fixed("33333333-0000-0000-0000-000000000001"),
                    volumeID: keels.id,
                    minutes: 12,
                    pace: keels.pace,
                    day: today,
                    loggedUnix: unix - 2_000
                ),
            ],
            marks: [],
            lamp: nil
        )

        let voyage = Isle(
            id: fixed("44444444-4444-4444-4444-444444444444"),
            drift: .voyage,
            volumes: [reach],
            mooredID: reach.id,
            sittings: [
                Sitting(
                    id: fixed("44444444-0000-0000-0000-000000000001"),
                    volumeID: reach.id,
                    minutes: 50,
                    pace: reach.pace,
                    day: today,
                    loggedUnix: unix - 10_000
                ),
                Sitting(
                    id: fixed("44444444-0000-0000-0000-000000000002"),
                    volumeID: reach.id,
                    minutes: 20,
                    pace: reach.pace,
                    day: today,
                    loggedUnix: unix - 4_000
                ),
            ],
            marks: [
                TileMark(
                    id: fixed("44444444-AAAA-0000-0000-000000000001"),
                    index: 1,
                    day: today,
                    steppedUnix: unix - 9_000
                ),
                TileMark(
                    id: fixed("44444444-AAAA-0000-0000-000000000002"),
                    index: 2,
                    day: today,
                    steppedUnix: unix - 6_000
                ),
                TileMark(
                    id: fixed("44444444-AAAA-0000-0000-000000000003"),
                    index: 3,
                    day: today,
                    steppedUnix: unix - 3_000
                ),
            ],
            lamp: Lamp(day: today, litUnix: unix - 9_000)
        )

        return Archipelago(
            isles: [fable, lyric, chronicle, voyage],
            onboardingComplete: true
        )
    }
}
