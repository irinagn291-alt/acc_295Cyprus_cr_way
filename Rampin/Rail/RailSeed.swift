import Foundation

/// Role: Rail. Simulator demo crate. Device never writes this. Key: rmp.demo.v1. Spreads three Waiting canvases so the first tap lifts. Never Bare.
enum RailSeed {
    private static func fixed(_ value: String) -> UUID {
        UUID(uuidString: value) ?? UUID()
    }

    static func rail(
        now: Date = Date(),
        calendar: Calendar = .current,
        shelf: [CatalogRow] = PmaShelf.bundled.rows
    ) -> Rail {
        let today = Daykey.stamp(now, calendar: calendar)
        func work(_ row: CatalogRow, id: UUID, seat: WorkSeat, dayOffset: Int) -> Work {
            var item = Work.waiting(from: row, id: id, daykey: Daykey.shifting(today, by: dayOffset, calendar: calendar))
            item.seat = seat
            return item
        }

        let rows = shelf
        let clinic = work(rows[0], id: fixed("AAAAAAAA-0001-4000-8000-000000000001"), seat: .waiting, dayOffset: 0)
        let nude = work(rows[1], id: fixed("AAAAAAAA-0001-4000-8000-000000000002"), seat: .waiting, dayOffset: -1)
        let kingdom = work(rows[2], id: fixed("AAAAAAAA-0001-4000-8000-000000000003"), seat: .hooked, dayOffset: -2)
        let prometheus = work(rows[3], id: fixed("AAAAAAAA-0001-4000-8000-000000000004"), seat: .waiting, dayOffset: -3)
        let annunciation = work(rows[4], id: fixed("AAAAAAAA-0001-4000-8000-000000000005"), seat: .waiting, dayOffset: -4)
        let loge = work(rows[5], id: fixed("AAAAAAAA-0001-4000-8000-000000000006"), seat: .settled, dayOffset: -5)
        let burning = work(rows[6], id: fixed("AAAAAAAA-0001-4000-8000-000000000007"), seat: .settled, dayOffset: -6)
        let museum = work(rows[7], id: fixed("AAAAAAAA-0001-4000-8000-000000000008"), seat: .waiting, dayOffset: -7)

        let field = CartelField.title
        let pegClinic = Rampin(
            id: fixed("CCCCCCCC-0001-4000-8000-000000000001"),
            workID: clinic.id,
            cartel: Cartel(field: field, text: clinic.title),
            isStruck: false
        )
        let pegNude = Rampin(
            id: fixed("CCCCCCCC-0001-4000-8000-000000000002"),
            workID: nude.id,
            cartel: Cartel(field: field, text: nude.title),
            isStruck: true
        )
        let pegKingdom = Rampin(
            id: fixed("CCCCCCCC-0001-4000-8000-000000000003"),
            workID: kingdom.id,
            cartel: Cartel(field: field, text: kingdom.title),
            isStruck: false
        )

        let hookMarks = [
            HookMark(
                id: fixed("BBBBBBBB-0001-4000-8000-000000000001"),
                workID: kingdom.id,
                rampinID: pegKingdom.id,
                field: field,
                cartelText: kingdom.title,
                daykey: kingdom.daykey
            ),
            HookMark(
                id: fixed("BBBBBBBB-0001-4000-8000-000000000002"),
                workID: loge.id,
                rampinID: fixed("CCCCCCCC-0001-4000-8000-000000000010"),
                field: field,
                cartelText: loge.title,
                daykey: loge.daykey
            ),
        ]
        let dropMarks = [
            DropMark(
                id: fixed("DDDDDDDD-0001-4000-8000-000000000001"),
                workID: clinic.id,
                rampinID: pegNude.id,
                field: field,
                cartelText: nude.title,
                daykey: clinic.daykey
            ),
            DropMark(
                id: fixed("DDDDDDDD-0001-4000-8000-000000000002"),
                workID: nude.id,
                rampinID: pegClinic.id,
                field: field,
                cartelText: clinic.title,
                daykey: nude.daykey
            ),
            DropMark(
                id: fixed("DDDDDDDD-0001-4000-8000-000000000003"),
                workID: clinic.id,
                rampinID: pegKingdom.id,
                field: field,
                cartelText: kingdom.title,
                daykey: clinic.daykey
            ),
        ]

        return Rail(
            schemaVersion: Rail.currentSchema,
            onboardingComplete: true,
            works: [clinic, nude, kingdom, prometheus, annunciation, loge, burning, museum],
            fold: .spread,
            planted: [pegClinic, pegNude, pegKingdom],
            cartelField: field,
            liftedWorkID: clinic.id,
            hookMarks: hookMarks,
            dropMarks: dropMarks,
            peelLog: [
                PeelRef(kind: .drop, markID: dropMarks[0].id),
                PeelRef(kind: .drop, markID: dropMarks[1].id),
                PeelRef(kind: .drop, markID: dropMarks[2].id),
                PeelRef(kind: .hook, markID: hookMarks[0].id),
            ],
            cachedRows: Array(rows.prefix(8)),
            focusedWorkID: clinic.id
        )
    }
}
