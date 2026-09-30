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
    }

    var rail: Rail {
        Rail(
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
