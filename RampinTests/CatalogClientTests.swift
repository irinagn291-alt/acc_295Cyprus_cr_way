import XCTest
@testable import Rampin

final class CatalogClientTests: XCTestCase {
    func test_searchRequest_mapsCgiPageOntoSparql() {
        let request = CatalogClient.searchRequest(query: "eakins", page: 2, pageSize: 10)
        XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), CatalogClient.userAgent)
        XCTAssertEqual(request.url?.host, "query.wikidata.org")
        XCTAssertEqual(request.url?.path, "/sparql")
        let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let query = items.first { $0.name == "query" }?.value ?? ""
        let format = items.first { $0.name == "format" }?.value
        XCTAssertEqual(format, "json")
        XCTAssertTrue(query.contains("wd:Q510324"))
        XCTAssertTrue(query.contains("LIMIT 10"))
        XCTAssertTrue(query.contains("OFFSET 10"))
        XCTAssertTrue(query.contains("wdt:P195"))
        XCTAssertTrue(query.contains("wdt:P170") || query.contains("wdt:P1476"))
        XCTAssertTrue(query.contains("wdt:P18"))
        XCTAssertFalse(query.contains("openfoodfacts"))
        XCTAssertFalse(query.contains("api.artic.edu"))
    }

    func test_userAgentIsThisApp() {
        XCTAssertEqual(CatalogClient.userAgent, "Rampin/1.0 (iOS; +https://rampin-hook.pro)")
        let entity = CatalogClient.entityRequest(objectID: "Q773861")
        XCTAssertEqual(entity.value(forHTTPHeaderField: "User-Agent"), CatalogClient.userAgent)
        XCTAssertTrue(entity.url?.absoluteString.contains("Special:EntityData/Q773861.json") ?? false)
    }

    func test_emptyQueryNeverHitsCarrier() async throws {
        let probe = ScriptedCarrier { _ in
            XCTFail("empty query must not hit the network")
            throw CatalogFault.transport
        }
        let client = CatalogClient(carrier: probe)
        let rows = try await client.search(query: "  ")
        XCTAssertTrue(rows.isEmpty)
    }

    func test_mapsEntityData_identityPrefersAccession() async throws {
        let probe = ScriptedCarrier { request in
            let url = request.url?.absoluteString ?? ""
            if url.contains("/sparql") {
                return (Self.sparqlData, Self.ok(url))
            }
            if url.contains("Special:EntityData/Q773861") {
                return (Self.entityData, Self.ok(url))
            }
            return (Data(), Self.http(url, 404))
        }
        let client = CatalogClient(carrier: probe)
        let rows = try await client.search(query: "gross")
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].objectID, "2007-1-1")
        XCTAssertEqual(rows[0].artist, "Thomas Eakins")
        XCTAssertEqual(rows[0].title, "The Gross Clinic")
        XCTAssertTrue(rows[0].imageURLString?.contains("Special:FilePath/") ?? false)
        XCTAssertTrue(rows[0].imageURLString?.contains("width=843") ?? false)
    }

    func test_malformedJSON_isTypedError() async {
        let probe = ScriptedCarrier { request in
            (Data("not-json".utf8), Self.ok(request.url?.absoluteString ?? ""))
        }
        let client = CatalogClient(carrier: probe)
        do {
            _ = try await client.search(query: "eakins")
            XCTFail("expected malformed")
        } catch let fault as CatalogFault {
            XCTAssertEqual(fault, .malformed)
        } catch {
            XCTFail("wrong error \(error)")
        }
    }

    func test_404DoesNotRetry() async {
        let probe = CountingCarrier { request in
            (Data(), Self.http(request.url?.absoluteString ?? "", 404))
        }
        let client = CatalogClient(carrier: probe)
        do {
            _ = try await client.search(query: "missing")
            XCTFail("expected missing")
        } catch let fault as CatalogFault {
            XCTAssertEqual(fault, .missing)
        } catch {
            XCTFail("wrong error \(error)")
        }
        let hits = await probe.hits
        XCTAssertEqual(hits, 1)
    }

    func test_transientTransportRetriesOnce() async {
        let probe = CountingCarrier { request in
            throw URLError(.timedOut)
        }
        let client = CatalogClient(carrier: probe)
        do {
            _ = try await client.search(query: "eakins")
            XCTFail("expected transport")
        } catch let fault as CatalogFault {
            XCTAssertEqual(fault, .transport)
        } catch {
            XCTFail("wrong error \(error)")
        }
        let hits = await probe.hits
        XCTAssertEqual(hits, 2)
    }

    func test_commonsFilePathEncodesName() {
        let path = CatalogClient.commonsFilePath("Thomas Eakins, American - Portrait.jpg")
        XCTAssertTrue(path.hasPrefix("https://commons.wikimedia.org/wiki/Special:FilePath/"))
        XCTAssertTrue(path.contains("width=843"))
        XCTAssertFalse(path.contains(" "))
        let script = CatalogClient.thumbScriptURL(from: path)
        XCTAssertEqual(
            script?.absoluteString.contains("thumb.php"),
            true
        )
        XCTAssertEqual(script?.absoluteString.contains("width=843"), true)
    }

    func test_decoderUsesDefaultKeys() {
        let data = Data(#"{"results":{"bindings":[]}}"#.utf8)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        XCTAssertNoThrow(try decoder.decode(SparqlEnvelopeDTO.self, from: data))
    }

    private static func ok(_ url: String) -> URLResponse {
        http(url, 200)
    }

    private static func http(_ url: String, _ code: Int) -> URLResponse {
        HTTPURLResponse(
            url: URL(string: url) ?? URL(string: "https://query.wikidata.org/sparql")!,
            statusCode: code,
            httpVersion: nil,
            headerFields: nil
        )!
    }

    private static let sparqlData = Data(
        """
        {"results":{"bindings":[{
          "item":{"type":"uri","value":"http://www.wikidata.org/entity/Q773861"},
          "itemLabel":{"type":"literal","value":"The Gross Clinic"},
          "creatorLabel":{"type":"literal","value":"Thomas Eakins"},
          "image":{"type":"uri","value":"http://commons.wikimedia.org/wiki/Special:FilePath/Gross.jpg"}
        }]}}
        """.utf8
    )

    private static let entityData = Data(
        """
        {"entities":{"Q773861":{
          "id":"Q773861",
          "labels":{"en":{"language":"en","value":"The Gross Clinic"}},
          "claims":{
            "P170":[{"mainsnak":{"datavalue":{"value":{"id":"Q557"}}}}],
            "P1476":[{"mainsnak":{"datavalue":{"value":{"text":"The Gross Clinic","language":"en"}}}}],
            "P217":[{"mainsnak":{"datavalue":{"value":"2007-1-1"}}}],
            "P18":[{"mainsnak":{"datavalue":{"value":"Thomas Eakins, American - Portrait of Dr. Samuel D. Gross (The Gross Clinic) - Google Art Project.jpg"}}}]
          }
        }}}
        """.utf8
    )
}

private struct ScriptedCarrier: CatalogCarrying {
    let handler: @Sendable (URLRequest) async throws -> (Data, URLResponse)

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await handler(request)
    }
}

private actor CountingCarrier: CatalogCarrying {
    private var count = 0
    private let handler: @Sendable (URLRequest) async throws -> (Data, URLResponse)

    init(handler: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse)) {
        self.handler = handler
    }

    var hits: Int { count }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        count += 1
        return try await handler(request)
    }
}
