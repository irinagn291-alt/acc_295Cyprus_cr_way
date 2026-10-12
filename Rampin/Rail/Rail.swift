import Foundation

/// Role: Rail. Closed algebraic fold Bare, Spread, or Settled. A fourth case is a defect.
enum RailFold: String, Equatable, Sendable, Codable {
    case bare
    case spread
    case settled
}

/// Role: Rail. Caption under a canvas. Waiting, Lifted, or Hooked. Never a riddle.
enum CanvasCaption: String, Equatable, Sendable {
    case waiting
    case lifted
    case hooked
    case settled
}

/// Role: Rail. Typed refusals of Spread, Lift, Hook, Drop, and Retract. Views map these.
enum RailFault: Error, Equatable, Sendable {
    case alreadySpread
    case hookWithoutLift
    case dropWithoutLift
    case unknownWork
    case unknownRampin
    case notWaiting
    case notSpread
    case emptyObjectID
    case nothingToPeel
}

/// Role: Rail. Explore save outcome. Duplicate accession focuses and does not reset the fold.
enum WriteFocus: Equatable, Sendable {
    case inserted(UUID)
    case focused(UUID)
}

/// Role: Rail. Recoverable load outcome. Never crash on a corrupt snapshot.
enum RailWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedEmpty
}

/// Role: Rail. Ordered retract stack. Retract peels the newest HookMark or DropMark.
enum PeelKind: String, Codable, Sendable {
    case hook
    case drop
}

struct PeelRef: Equatable, Sendable, Codable {
    var kind: PeelKind
    var markID: UUID
}

/// Role: Rail. A sentence the handler writes on a saved work. It stays on this device.
struct WallLabel: Equatable, Sendable, Codable {
    var objectID: String
    var text: String
    var daykey: Int
}

/// Role: Rail. One settled trio. Drops are the misses counted from the spread that seated it.
struct RailRun: Equatable, Sendable, Codable, Identifiable {
    var id: UUID
    var objectIDs: [String]
    var field: CartelField
    var drops: Int
    var daykey: Int
    var baseline: Int
}

/// Role: Rail. In-memory fold over Works. Views call spreadRail, liftWork, hookRampin, dropRampin, and retractNewestMark. Never a second rail enum.
struct Rail: Equatable, Sendable {
    var schemaVersion: Int
    var onboardingComplete: Bool
    var works: [Work]
    var fold: RailFold
    var planted: [Rampin]
    var cartelField: CartelField?
    var liftedWorkID: UUID?
    var hookMarks: [HookMark]
    var dropMarks: [DropMark]
    var peelLog: [PeelRef]
    var cachedRows: [CatalogRow]
    var focusedWorkID: UUID?
    var preferredField: CartelField = .title
    var labels: [WallLabel] = []
    var runs: [RailRun] = []
    var spreadDropBaseline: Int?

    static let currentSchema = 1
    static let labelLimit = 180

    static let empty = Rail(
        schemaVersion: currentSchema,
        onboardingComplete: false,
        works: [],
        fold: .bare,
        planted: [],
        cartelField: nil,
        liftedWorkID: nil,
        hookMarks: [],
        dropMarks: [],
        peelLog: [],
        cachedRows: [],
        focusedWorkID: nil
    )

    var waitingWorks: [Work] {
        works.filter(\.seat.isWaiting)
    }

    var hookedWorks: [Work] {
        works.filter(\.seat.isHooked)
    }

    var settledWorks: [Work] {
        works.filter(\.seat.isSettled)
    }

    var hookPool: [Work] {
        works.filter { !$0.seat.isSettled }
    }

    var reviewableDrops: [DropMark] {
        dropMarks
    }

    var reviewableHooks: [HookMark] {
        hookMarks
    }

    var liftedWork: Work? {
        guard let liftedWorkID else { return nil }
        return works.first { $0.id == liftedWorkID }
    }

    var canSpread: Bool {
        fold != .spread
    }

    var readyToSpread: Bool {
        fold != .spread && waitingWorks.count >= 3
    }

    var missIDs: Set<UUID> {
        let waiting = Set(waitingWorks.map(\.id))
        return Set(dropMarks.map(\.workID)).intersection(waiting)
    }

    var canSpreadMisses: Bool {
        guard fold != .spread else { return false }
        let dropped = works.filter { work in
            dropMarks.contains { $0.workID == work.id } && (work.seat.isWaiting || work.seat.isSettled)
        }
        guard !dropped.isEmpty else { return false }
        let fillers = waitingWorks.filter { work in
            !dropMarks.contains { $0.workID == work.id }
        }
        return dropped.count + fillers.count >= 3
    }

    func labelText(for objectID: String) -> String? {
        labels.first { $0.objectID == objectID }?.text
    }

    var makerTallies: [(name: String, count: Int)] {
        let groups = Dictionary(grouping: settledWorks, by: \.artist)
        return groups
            .map { (name: $0.key, count: $0.value.count) }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
    }

    var canLift: Bool {
        fold == .spread && waitingOnRail.contains(where: { $0.seat.isWaiting })
    }

    var canHook: Bool {
        fold == .spread && liftedWorkID != nil
    }

    var waitingOnRail: [Work] {
        planted.compactMap { peg in
            works.first { $0.id == peg.workID && $0.seat.isWaiting }
        }
    }

    func caption(for workID: UUID) -> CanvasCaption {
        guard let work = works.first(where: { $0.id == workID }) else { return .waiting }
        if work.seat.isSettled { return .settled }
        if work.seat.isHooked { return .hooked }
        if liftedWorkID == work.id { return .lifted }
        return .waiting
    }

    mutating func spreadRail(preferring field: CartelField? = nil, misses: Bool = false) throws {
        if fold == .spread {
            throw RailFault.alreadySpread
        }
        let sample = Self.sampleWaiting(from: works, misses: misses ? missIDs : [])
        guard sample.count == 3 else {
            fold = .bare
            planted = []
            cartelField = nil
            liftedWorkID = nil
            spreadDropBaseline = nil
            return
        }
        let chosen = Self.chooseField(for: sample, preferring: field ?? preferredField)
        planted = sample.map { work in
            Rampin(
                id: UUID(),
                workID: work.id,
                cartel: Cartel(field: chosen, text: work.cartelText(for: chosen)),
                isStruck: false
            )
        }
        cartelField = chosen
        liftedWorkID = nil
        spreadDropBaseline = dropMarks.count
        fold = .spread
    }

    /// Puts missed works back on the waiting rail, then spreads with those works first.
    mutating func spreadMisses() throws {
        var chosen: [UUID] = []
        for id in dropMarks.reversed().map(\.workID) where !chosen.contains(id) {
            chosen.append(id)
            if chosen.count == 3 { break }
        }
        for id in chosen {
            if let index = works.firstIndex(where: { $0.id == id && $0.seat.isSettled }) {
                works[index].seat = .waiting
            }
        }
        try spreadRail(misses: true)
    }

    mutating func writeLabel(
        _ objectID: String,
        text: String,
        now: Date = Date(),
        calendar: Calendar = .current
    ) throws {
        let id = objectID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard works.contains(where: { $0.objectID == id }) else { throw RailFault.unknownWork }
        let trimmed = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.labelLimit))
        if trimmed.isEmpty {
            labels.removeAll { $0.objectID == id }
            return
        }
        let stamp = Daykey.stamp(now, calendar: calendar)
        if let index = labels.firstIndex(where: { $0.objectID == id }) {
            labels[index].text = trimmed
            labels[index].daykey = stamp
        } else {
            labels.append(WallLabel(objectID: id, text: trimmed, daykey: stamp))
        }
    }

    mutating func liftWork(_ workID: UUID) throws {
        guard fold == .spread else { throw RailFault.notSpread }
        guard planted.contains(where: { $0.workID == workID }) else {
            throw RailFault.unknownWork
        }
        guard let work = works.first(where: { $0.id == workID }) else {
            throw RailFault.unknownWork
        }
        guard work.seat.isWaiting else { throw RailFault.notWaiting }
        liftedWorkID = work.id
    }

    @discardableResult
    mutating func hookRampin(
        _ rampinID: UUID,
        markID: UUID = UUID(),
        now: Date = Date(),
        calendar: Calendar = .current
    ) throws -> PeelKind {
        guard fold == .spread else { throw RailFault.notSpread }
        guard liftedWorkID != nil else { throw RailFault.hookWithoutLift }
        guard let peg = planted.first(where: { $0.id == rampinID }) else {
            throw RailFault.unknownRampin
        }
        guard let work = liftedWork else { throw RailFault.unknownWork }
        if peg.names(work) {
            try fileHook(peg: peg, work: work, markID: markID, now: now, calendar: calendar)
            return .hook
        }
        try fileDrop(peg: peg, work: work, markID: markID, now: now, calendar: calendar)
        return .drop
    }

    mutating func dropRampin(
        _ rampinID: UUID,
        markID: UUID = UUID(),
        now: Date = Date(),
        calendar: Calendar = .current
    ) throws {
        guard fold == .spread else { throw RailFault.notSpread }
        guard liftedWorkID != nil else { throw RailFault.dropWithoutLift }
        guard let peg = planted.first(where: { $0.id == rampinID }) else {
            throw RailFault.unknownRampin
        }
        guard let work = liftedWork else { throw RailFault.unknownWork }
        try fileDrop(peg: peg, work: work, markID: markID, now: now, calendar: calendar)
    }

    mutating func retractNewestMark() throws {
        guard let last = peelLog.popLast() else {
            throw RailFault.nothingToPeel
        }
        switch last.kind {
        case .hook:
            peelHook(markID: last.markID)
        case .drop:
            peelDrop(markID: last.markID)
        }
    }

    @discardableResult
    mutating func fileWork(
        _ row: CatalogRow,
        now: Date = Date(),
        calendar: Calendar = .current,
        id: UUID = UUID()
    ) throws -> WriteFocus {
        let objectID = row.objectID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !objectID.isEmpty else { throw RailFault.emptyObjectID }
        if let existing = works.first(where: { $0.objectID == objectID }) {
            focusedWorkID = existing.id
            return .focused(existing.id)
        }
        var incoming = row
        incoming.objectID = objectID
        let work = Work.waiting(from: incoming, id: id, daykey: Daykey.stamp(now, calendar: calendar))
        works.append(work)
        remember(incoming)
        focusedWorkID = work.id
        return .inserted(work.id)
    }

    mutating func remember(_ rows: [CatalogRow]) {
        for row in rows {
            remember(row)
        }
    }

    mutating func remember(_ row: CatalogRow) {
        let objectID = row.objectID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !objectID.isEmpty else { return }
        var stored = row
        stored.objectID = objectID
        if let index = cachedRows.firstIndex(where: { $0.objectID == objectID }) {
            cachedRows[index] = stored
        } else {
            cachedRows.append(stored)
        }
    }

    mutating func setOnboardingComplete(_ flag: Bool) {
        onboardingComplete = flag
    }

    mutating func resetAllData() {
        self = .empty
    }

    func fallbackRows(shelf: [CatalogRow]) -> [CatalogRow] {
        var seen = Set<String>()
        var merged: [CatalogRow] = []
        let shelfByID = Dictionary(uniqueKeysWithValues: shelf.map { ($0.objectID, $0) })
        for row in cachedRows + shelf {
            var next = row
            if let fresh = shelfByID[row.objectID], let image = fresh.imageURLString, !image.isEmpty {
                next.imageURLString = image
            }
            if seen.insert(next.objectID).inserted {
                merged.append(next)
            }
        }
        return merged
    }

    mutating func applyShelfImages(_ shelf: [CatalogRow]) {
        let shelfByID = Dictionary(uniqueKeysWithValues: shelf.map { ($0.objectID, $0) })
        for index in works.indices {
            if let row = shelfByID[works[index].objectID], let image = row.imageURLString, !image.isEmpty {
                works[index].imageURLString = image
            }
        }
        for index in cachedRows.indices {
            if let row = shelfByID[cachedRows[index].objectID], let image = row.imageURLString, !image.isEmpty {
                cachedRows[index].imageURLString = image
            }
        }
    }

    static func sampleWaiting(from works: [Work], misses: Set<UUID> = []) -> [Work] {
        func ordered(_ items: [Work]) -> [Work] {
            items.sorted { lhs, rhs in
                if lhs.daykey != rhs.daykey { return lhs.daykey < rhs.daykey }
                return lhs.objectID < rhs.objectID
            }
        }
        let waiting = works.filter(\.seat.isWaiting)
        guard !misses.isEmpty else {
            return Array(ordered(waiting).prefix(3))
        }
        let first = ordered(waiting.filter { misses.contains($0.id) })
        let rest = ordered(waiting.filter { !misses.contains($0.id) })
        return Array((first + rest).prefix(3))
    }

    static func chooseField(for works: [Work], preferring preferred: CartelField) -> CartelField {
        let artistOK = uniqueTexts(works.map(\.artist))
        let titleOK = uniqueTexts(works.map(\.title))
        switch preferred {
        case .artist:
            if artistOK { return .artist }
            if titleOK { return .title }
            return .artist
        case .title:
            if titleOK { return .title }
            if artistOK { return .artist }
            return .title
        }
    }

    private static func uniqueTexts(_ values: [String]) -> Bool {
        let trimmed = values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard trimmed.allSatisfy({ !$0.isEmpty }) else { return false }
        return Set(trimmed).count == trimmed.count
    }

    private mutating func fileHook(
        peg: Rampin,
        work: Work,
        markID: UUID,
        now: Date,
        calendar: Calendar
    ) throws {
        guard let index = works.firstIndex(where: { $0.id == work.id }) else {
            throw RailFault.unknownWork
        }
        works[index].seat = .hooked
        liftedWorkID = nil
        if let pegIndex = planted.firstIndex(where: { $0.id == peg.id }) {
            planted[pegIndex].isStruck = false
        }
        let mark = HookMark(
            id: markID,
            workID: work.id,
            rampinID: peg.id,
            field: peg.cartel.field,
            cartelText: peg.cartel.text,
            daykey: Daykey.stamp(now, calendar: calendar)
        )
        hookMarks.append(mark)
        peelLog.append(PeelRef(kind: .hook, markID: markID))
        focusedWorkID = work.id
        let hookedOnRail = planted.filter { peg in
            works.contains { $0.id == peg.workID && $0.seat.isHooked }
        }
        if hookedOnRail.count == 3 {
            settlePlanted(now: now, calendar: calendar)
        }
    }

    private mutating func fileDrop(
        peg: Rampin,
        work: Work,
        markID: UUID,
        now: Date,
        calendar: Calendar
    ) throws {
        guard let index = works.firstIndex(where: { $0.id == work.id }) else {
            throw RailFault.unknownWork
        }
        works[index].seat = .waiting
        liftedWorkID = nil
        if let pegIndex = planted.firstIndex(where: { $0.id == peg.id }) {
            planted[pegIndex].isStruck = true
        }
        let mark = DropMark(
            id: markID,
            workID: work.id,
            rampinID: peg.id,
            field: peg.cartel.field,
            cartelText: peg.cartel.text,
            daykey: Daykey.stamp(now, calendar: calendar)
        )
        dropMarks.append(mark)
        peelLog.append(PeelRef(kind: .drop, markID: markID))
        focusedWorkID = work.id
    }

    private mutating func settlePlanted(now: Date, calendar: Calendar) {
        let baseline = spreadDropBaseline ?? dropMarks.count
        let drops = max(0, dropMarks.count - baseline)
        let ids = planted.compactMap { peg in
            works.first { $0.id == peg.workID }?.objectID
        }
        for peg in planted {
            if let index = works.firstIndex(where: { $0.id == peg.workID }) {
                works[index].seat = .settled
            }
        }
        if ids.count == 3, let field = cartelField {
            runs.append(
                RailRun(
                    id: UUID(),
                    objectIDs: ids,
                    field: field,
                    drops: drops,
                    daykey: Daykey.stamp(now, calendar: calendar),
                    baseline: baseline
                )
            )
        }
        spreadDropBaseline = nil
        fold = .settled
        liftedWorkID = nil
    }

    private mutating func peelHook(markID: UUID) {
        guard let markIndex = hookMarks.firstIndex(where: { $0.id == markID }) else { return }
        let mark = hookMarks.remove(at: markIndex)
        if let workIndex = works.firstIndex(where: { $0.id == mark.workID }) {
            works[workIndex].seat = .waiting
        }
        if fold == .settled {
            for peg in planted where peg.workID != mark.workID {
                if let workIndex = works.firstIndex(where: { $0.id == peg.workID }) {
                    works[workIndex].seat = .hooked
                }
            }
            fold = .spread
            let plantedIDs = Set(planted.compactMap { peg in
                works.first { $0.id == peg.workID }?.objectID
            })
            if let last = runs.last, Set(last.objectIDs) == plantedIDs {
                spreadDropBaseline = runs.removeLast().baseline
            }
        }
        liftedWorkID = nil
        if let pegIndex = planted.firstIndex(where: { $0.id == mark.rampinID }) {
            planted[pegIndex].isStruck = false
        }
    }

    private mutating func peelDrop(markID: UUID) {
        guard let markIndex = dropMarks.firstIndex(where: { $0.id == markID }) else { return }
        let mark = dropMarks.remove(at: markIndex)
        if let pegIndex = planted.firstIndex(where: { $0.id == mark.rampinID }) {
            planted[pegIndex].isStruck = false
        }
        liftedWorkID = nil
    }
}
