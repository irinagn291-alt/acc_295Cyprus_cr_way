import Foundation

/// Role: Rail. Codable RailDocument. schemaVersion from 1. Rampin fold is stored. Settled-ness is not a parallel bool.
struct RailDocument: Equatable, Sendable, Codable {
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
    var preferredField: CartelField
    var labels: [WallLabel]
    var runs: [RailRun]
    var spreadDropBaseline: Int?

    init(rail: Rail) {
        schemaVersion = rail.schemaVersion
        onboardingComplete = rail.onboardingComplete
        works = rail.works
        fold = rail.fold
        planted = rail.planted
        cartelField = rail.cartelField
        liftedWorkID = rail.liftedWorkID
        hookMarks = rail.hookMarks
        dropMarks = rail.dropMarks
        peelLog = rail.peelLog
        cachedRows = rail.cachedRows
        focusedWorkID = rail.focusedWorkID
        preferredField = rail.preferredField
        labels = rail.labels
        runs = rail.runs
        spreadDropBaseline = rail.spreadDropBaseline
    }

    var rail: Rail {
        var next = Rail(
            schemaVersion: schemaVersion,
            onboardingComplete: onboardingComplete,
            works: works,
            fold: fold,
            planted: planted,
            cartelField: cartelField,
            liftedWorkID: liftedWorkID,
            hookMarks: hookMarks,
            dropMarks: dropMarks,
            peelLog: peelLog,
            cachedRows: cachedRows,
            focusedWorkID: focusedWorkID
        )
        next.preferredField = preferredField
        next.labels = labels
        next.runs = runs
        next.spreadDropBaseline = spreadDropBaseline
        return next
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case onboardingComplete
        case works
        case fold
        case planted
        case cartelField
        case liftedWorkID
        case hookMarks
        case dropMarks
        case peelLog
        case cachedRows
        case focusedWorkID
        case preferredField
        case labels
        case runs
        case spreadDropBaseline
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        onboardingComplete = try container.decode(Bool.self, forKey: .onboardingComplete)
        works = try container.decode([Work].self, forKey: .works)
        fold = try container.decode(RailFold.self, forKey: .fold)
        planted = try container.decode([Rampin].self, forKey: .planted)
        cartelField = try container.decodeIfPresent(CartelField.self, forKey: .cartelField)
        liftedWorkID = try container.decodeIfPresent(UUID.self, forKey: .liftedWorkID)
        hookMarks = try container.decode([HookMark].self, forKey: .hookMarks)
        dropMarks = try container.decode([DropMark].self, forKey: .dropMarks)
        peelLog = try container.decode([PeelRef].self, forKey: .peelLog)
        cachedRows = try container.decode([CatalogRow].self, forKey: .cachedRows)
        focusedWorkID = try container.decodeIfPresent(UUID.self, forKey: .focusedWorkID)
        preferredField = try container.decodeIfPresent(CartelField.self, forKey: .preferredField) ?? .title
        labels = try container.decodeIfPresent([WallLabel].self, forKey: .labels) ?? []
        runs = try container.decodeIfPresent([RailRun].self, forKey: .runs) ?? []
        spreadDropBaseline = try container.decodeIfPresent(Int.self, forKey: .spreadDropBaseline)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(onboardingComplete, forKey: .onboardingComplete)
        try container.encode(works, forKey: .works)
        try container.encode(fold, forKey: .fold)
        try container.encode(planted, forKey: .planted)
        try container.encodeIfPresent(cartelField, forKey: .cartelField)
        try container.encodeIfPresent(liftedWorkID, forKey: .liftedWorkID)
        try container.encode(hookMarks, forKey: .hookMarks)
        try container.encode(dropMarks, forKey: .dropMarks)
        try container.encode(peelLog, forKey: .peelLog)
        try container.encode(cachedRows, forKey: .cachedRows)
        try container.encodeIfPresent(focusedWorkID, forKey: .focusedWorkID)
        try container.encode(preferredField, forKey: .preferredField)
        try container.encode(labels, forKey: .labels)
        try container.encode(runs, forKey: .runs)
        try container.encodeIfPresent(spreadDropBaseline, forKey: .spreadDropBaseline)
    }

    static func encode(_ rail: Rail) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        var copy = rail
        copy.schemaVersion = Rail.currentSchema
        return try encoder.encode(RailDocument(rail: copy))
    }

    static func decode(_ data: Data) throws -> Rail {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw RailCodecError.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                var rail = try decoder.decode(RailDocument.self, from: data).rail
                rail.schemaVersion = Rail.currentSchema
                return rail
            } catch let error as RailCodecError {
                throw error
            } catch {
                throw RailCodecError.corrupt
            }
        default:
            throw RailCodecError.unsupportedSchema(probe.schemaVersion)
        }
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}
