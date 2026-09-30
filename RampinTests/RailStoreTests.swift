import XCTest
@testable import Rampin

@MainActor
final class RailStoreTests: XCTestCase {
    func test_persistenceRoundTrip_writeReloadVerify() async throws {
        let directory = uniqueDirectory()
        let suite = uniqueSuite()
        let store = RailStore(
            directory: directory,
            suiteName: suite,
            writeDelayNanoseconds: 0,
            seekDelayNanoseconds: 0,
            plantDemo: false
        )
        await store.load()
        for row in PmaShelf.bundled.rows.prefix(3) {
            _ = try await store.fileWork(row)
        }
        try await store.spreadRail()
        let peg = store.rail.planted[0]
        try await store.liftWork(peg.workID)
        try await store.hookRampin(peg.id)
        let snapshot = store.rail

        let reloaded = RailStore(
            directory: directory,
            suiteName: suite,
            writeDelayNanoseconds: 0,
            seekDelayNanoseconds: 0,
            plantDemo: false
        )
        await reloaded.load()
        XCTAssertEqual(reloaded.rail.fold, snapshot.fold)
        XCTAssertEqual(reloaded.rail.works.map(\.objectID), snapshot.works.map(\.objectID))
        XCTAssertEqual(reloaded.rail.works.map(\.seat), snapshot.works.map(\.seat))
        XCTAssertEqual(reloaded.rail.hookMarks.count, 1)
        XCTAssertEqual(reloaded.rail.planted.map(\.workID), snapshot.planted.map(\.workID))
        XCTAssertEqual(reloaded.rail.cartelField, snapshot.cartelField)
    }

    func test_corruptSnapshotFallsBackToBackup() async throws {
        let directory = uniqueDirectory()
        let suite = uniqueSuite()
        let store = RailStore(
            directory: directory,
            suiteName: suite,
            writeDelayNanoseconds: 0,
            seekDelayNanoseconds: 0,
            plantDemo: false
        )
        await store.load()
        _ = try await store.fileWork(PmaShelf.bundled.rows[0])
        await store.flush()

        let box = UserDefaults(suiteName: suite)!
        let good = box.data(forKey: RailKey.snapshot)
        XCTAssertNotNil(good)
        box.set(good, forKey: RailKey.backup)
        box.set(Data("not-json".utf8), forKey: RailKey.snapshot)
        try? Data("not-json".utf8).write(to: directory.appendingPathComponent("rail.json"), options: .atomic)

        let recovered = RailStore(
            directory: directory,
            suiteName: suite,
            writeDelayNanoseconds: 0,
            seekDelayNanoseconds: 0,
            plantDemo: false
        )
        await recovered.load()
        XCTAssertEqual(recovered.warning, .recoveredFromBackup)
        XCTAssertEqual(recovered.rail.works.count, 1)
    }

    func test_resetAllData_emptiesMemoryAndSuite() async throws {
        let directory = uniqueDirectory()
        let suite = uniqueSuite()
        let store = RailStore(
            directory: directory,
            suiteName: suite,
            writeDelayNanoseconds: 0,
            seekDelayNanoseconds: 0,
            plantDemo: false
        )
        await store.load()
        _ = try await store.fileWork(PmaShelf.bundled.rows[0])
        await store.resetAllData()
        XCTAssertEqual(store.rail, .empty)
        let box = UserDefaults(suiteName: suite)!
        XCTAssertNil(box.data(forKey: RailKey.snapshot))
    }

    func test_emptyQueryDoesNotHitNetwork() async throws {
        let probe = ProbeCarrier()
        let store = RailStore(
            directory: uniqueDirectory(),
            suiteName: uniqueSuite(),
            client: CatalogClient(carrier: probe),
            writeDelayNanoseconds: 0,
            seekDelayNanoseconds: 0,
            plantDemo: false
        )
        await store.load()
        let rows = try await store.seek("   ")
        let hits = await probe.hits
        XCTAssertEqual(hits, 0)
        XCTAssertEqual(rows.count, PmaShelf.bundled.rows.count)
    }

    func test_documentUsesSchemaVersionOne() throws {
        let data = try RailDocument.encode(RailSeed.rail())
        let probe = try JSONDecoder().decode(VersionProbe.self, from: data)
        XCTAssertEqual(probe.schemaVersion, 1)
        let decoded = try RailDocument.decode(data)
        XCTAssertEqual(decoded.fold, .spread)
        XCTAssertEqual(decoded.works.count, 8)
    }

    private func uniqueDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func uniqueSuite() -> String {
        "rmp.test.\(UUID().uuidString)"
    }
}

private struct VersionProbe: Decodable {
    var schemaVersion: Int
}

private actor ProbeCarrier: CatalogCarrying {
    private var count = 0

    var hits: Int { count }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        count += 1
        throw URLError(.notConnectedToInternet)
    }
}
