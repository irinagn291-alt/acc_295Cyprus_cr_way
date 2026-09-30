import Foundation

/// Role: Work. Typed transport failures. DTO decode never crashes the crate.
enum CatalogFault: Error, Equatable, Sendable {
    case cancelled
    case missing
    case refused
    case transport
    case malformed
}

/// Role: Work. One HTTP hop. Injected so tests never leave the process.
protocol CatalogCarrying: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Role: Work. URLSession hop, 15 s timeout, app User-Agent on every request.
struct CatalogSession: CatalogCarrying {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = CatalogClient.timeout
        configuration.timeoutIntervalForResource = CatalogClient.timeout
        configuration.httpAdditionalHeaders = ["User-Agent": CatalogClient.userAgent]
        self.session = URLSession(configuration: configuration)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

struct SparqlEnvelopeDTO: Decodable, Sendable {
    var results: SparqlResultsDTO?
}

struct SparqlResultsDTO: Decodable, Sendable {
    var bindings: [SparqlBindingDTO]?
}

struct SparqlBindingDTO: Decodable, Sendable {
    var item: SparqlValueDTO?
    var itemLabel: SparqlValueDTO?
    var creatorLabel: SparqlValueDTO?
    var title: SparqlValueDTO?
    var accession: SparqlValueDTO?
    var image: SparqlValueDTO?

    enum CodingKeys: String, CodingKey {
        case item
        case itemLabel
        case creatorLabel
        case title
        case accession
        case image
    }

    var qid: String? {
        CatalogClient.qid(from: item?.value)
    }
}

struct SparqlValueDTO: Decodable, Sendable {
    var type: String?
    var value: String?
}

struct EntityDataDTO: Decodable, Sendable {
    var entities: [String: EntityDTO]?
}

struct EntityDTO: Decodable, Sendable {
    var id: String?
    var labels: [String: EntityLabelDTO]?
    var claims: [String: [EntityClaimDTO]]?

    enum CodingKeys: String, CodingKey {
        case id
        case labels
        case claims
    }

    var englishLabel: String? {
        let trimmed = (labels?["en"]?.value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var commonsFilename: String? {
        claims?["P18"]?.compactMap(\.stringValue).first
    }

    var nativeTitle: String? {
        claims?["P1476"]?.compactMap(\.stringValue).first
    }

    var accession: String? {
        claims?["P217"]?.compactMap(\.stringValue).first
    }

    var makerQID: String? {
        claims?["P170"]?.compactMap(\.entityID).first
    }
}

struct EntityLabelDTO: Decodable, Sendable {
    var language: String?
    var value: String?
}

struct EntityClaimDTO: Decodable, Sendable {
    var mainsnak: EntitySnakDTO?

    var stringValue: String? {
        mainsnak?.datavalue?.flexible.string
    }

    var entityID: String? {
        mainsnak?.datavalue?.flexible.entityID
    }
}

struct EntitySnakDTO: Decodable, Sendable {
    var datavalue: EntityDataValueDTO?
}

struct EntityDataValueDTO: Decodable, Sendable {
    var flexible: FlexibleWikidataValue

    enum CodingKeys: String, CodingKey {
        case value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        flexible = try container.decode(FlexibleWikidataValue.self, forKey: .value)
    }
}

enum FlexibleWikidataValue: Decodable, Sendable {
    case string(String)
    case object(Object)
    case unknown

    struct Object: Decodable, Sendable {
        var id: String?
        var text: String?
        var language: String?
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .string(string)
            return
        }
        if let object = try? container.decode(Object.self) {
            self = .object(object)
            return
        }
        self = .unknown
    }

    var string: String? {
        switch self {
        case .string(let value):
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        case .object(let object):
            let text = (object.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty { return text }
            let id = (object.id ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return id.isEmpty ? nil : id
        case .unknown:
            return nil
        }
    }

    var entityID: String? {
        switch self {
        case .object(let object):
            return CatalogClient.qid(from: object.id)
        case .string(let value):
            return CatalogClient.qid(from: value)
        case .unknown:
            return nil
        }
    }
}

/// Role: Work. Owns Philadelphia Museum of Art search via Wikidata SPARQL. cgi search pl maps to query, format=json, page, page_size. Never Open Food Facts. DTO then domain.
actor CatalogClient {
    static let userAgent = "Rampin/1.0 (iOS; +https://rampin-hook.pro)"
    static let timeout: TimeInterval = 15
    static let thumbWidth = 843
    static let searchHost = "query.wikidata.org"
    static let searchPath = "/sparql"
    static let entityHost = "www.wikidata.org"
    static let pmaQID = "Q510324"
    /// Programmer constant. The domain string is fixed in SPEC.md.
    static let contactURL = URL(string: "https://rampin-hook.pro/contact-us")!
    /// Programmer constant. Philadelphia Museum of Art credit lives on Settings.
    static let pmaHomeURL = URL(string: "https://www.philamuseum.org")!
    static let pmaOpenAccessURL = URL(string: "https://philamuseum.org/open-access")!
    static let searchURL = URL(string: "https://query.wikidata.org/sparql")!

    private let carrier: any CatalogCarrying
    private let decoder: JSONDecoder

    init(carrier: any CatalogCarrying) {
        self.carrier = carrier
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        self.decoder = decoder
    }

    init() {
        self.init(carrier: CatalogSession())
    }

    func search(query: String, page: Int = 1, pageSize: Int = 20) async throws -> [CatalogRow] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let request = Self.searchRequest(query: trimmed, page: page, pageSize: pageSize)
        let data = try await send(request)
        let dto: SparqlEnvelopeDTO
        do {
            dto = try decoder.decode(SparqlEnvelopeDTO.self, from: data)
        } catch is CancellationError {
            throw CatalogFault.cancelled
        } catch {
            throw CatalogFault.malformed
        }
        let bindings = dto.results?.bindings ?? []
        var rows: [CatalogRow] = []
        var seen = Set<String>()
        for binding in bindings {
            try Task.checkCancellation()
            guard let qid = binding.qid else { continue }
            let entity = try await fetchEntity(qid)
            if let row = Self.mapRow(binding: binding, entity: entity), seen.insert(row.objectID).inserted {
                rows.append(row)
            }
        }
        return rows
    }

    nonisolated static func searchRequest(
        query: String,
        page: Int = 1,
        pageSize: Int = 20
    ) -> URLRequest {
        let pageIndex = max(page, 1)
        let size = min(max(pageSize, 1), 50)
        let offset = (pageIndex - 1) * size
        var parts = URLComponents()
        parts.scheme = "https"
        parts.host = searchHost
        parts.path = searchPath
        parts.queryItems = [
            URLQueryItem(name: "query", value: sparql(needle: query, limit: size, offset: offset)),
            URLQueryItem(name: "format", value: "json"),
        ]
        var request = URLRequest(url: parts.url ?? searchURL, timeoutInterval: timeout)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/sparql-results+json", forHTTPHeaderField: "Accept")
        return request
    }

    nonisolated static func entityRequest(objectID: String) -> URLRequest {
        let url = entityURL(objectID: objectID)
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    nonisolated static func entityURL(objectID: String) -> URL {
        let safe = qid(from: objectID) ?? objectID
        return URL(string: "https://www.wikidata.org/wiki/Special:EntityData/\(safe).json")
            ?? URL(string: "https://www.wikidata.org/wiki/Special:EntityData/Q0.json")!
    }

    nonisolated static func commonsFilePath(_ filename: String) -> String {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/")
        let encoded = filename.addingPercentEncoding(withAllowedCharacters: allowed) ?? filename
        return "https://commons.wikimedia.org/wiki/Special:FilePath/\(encoded)?width=\(thumbWidth)"
    }

    nonisolated static func thumbScriptURL(from raw: String?) -> URL? {
        let trimmed = trim(raw)
        guard !trimmed.isEmpty else { return nil }
        if let name = filenameFromFilePath(trimmed) {
            return scriptURL(filename: name)
        }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return nil
        }
        return scriptURL(filename: trimmed)
    }

    nonisolated private static func scriptURL(filename: String) -> URL? {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=?")
        let encoded = filename.addingPercentEncoding(withAllowedCharacters: allowed) ?? filename
        return URL(string: "https://commons.wikimedia.org/w/thumb.php?f=\(encoded)&width=\(thumbWidth)")
    }

    nonisolated static func thumbURL(from raw: String?) -> URL? {
        guard let string = thumbURLString(from: raw) else { return nil }
        return URL(string: string)
    }

    nonisolated static func thumbURLString(from raw: String?) -> String? {
        let trimmed = trim(raw)
        guard !trimmed.isEmpty else { return nil }
        var value = trimmed
        if value.hasPrefix("http://") {
            value = "https://" + value.dropFirst("http://".count)
        }
        if let filename = filenameFromFilePath(value) {
            return commonsFilePath(filename)
        }
        return value
    }

    nonisolated static func filenameFromFilePath(_ value: String) -> String? {
        guard let marker = value.range(of: "Special:FilePath/", options: .caseInsensitive) else {
            return nil
        }
        var rest = String(value[marker.upperBound...])
        if let query = rest.firstIndex(of: "?") {
            rest = String(rest[..<query])
        }
        let decoded = rest.removingPercentEncoding ?? rest
        return decoded.isEmpty ? nil : decoded
    }

    nonisolated static func qid(from value: String?) -> String? {
        guard let value else { return nil }
        guard let range = value.range(of: #"Q[0-9]+$"#, options: .regularExpression) else {
            return nil
        }
        return String(value[range])
    }

    private func fetchEntity(_ objectID: String) async throws -> EntityDTO? {
        let request = Self.entityRequest(objectID: objectID)
        do {
            let data = try await send(request)
            let dto = try decoder.decode(EntityDataDTO.self, from: data)
            return dto.entities?[objectID] ?? dto.entities?.values.first
        } catch let fault as CatalogFault where fault == .cancelled {
            throw fault
        } catch {
            return nil
        }
    }

    private static func mapRow(binding: SparqlBindingDTO, entity: EntityDTO?) -> CatalogRow? {
        guard let qid = binding.qid else { return nil }
        let accession = firstNonEmpty([
            trim(entity?.accession),
            trim(binding.accession?.value),
        ])
        let objectID = accession.isEmpty ? qid : accession
        let artist = firstNonEmpty([
            trim(binding.creatorLabel?.value),
        ])
        let title = firstNonEmpty([
            entity?.nativeTitle,
            entity?.englishLabel,
            trim(binding.title?.value),
            trim(binding.itemLabel?.value),
        ])
        let filename = entity?.commonsFilename
        let image = firstNonEmpty([
            filename.map(commonsFilePath),
            thumbURLString(from: binding.image?.value),
        ])
        guard !artist.isEmpty, !title.isEmpty, !image.isEmpty else { return nil }
        return CatalogRow(
            objectID: objectID,
            artist: artist,
            title: title,
            imageURLString: image,
            dated: nil
        )
    }

    private static func firstNonEmpty(_ values: [String?]) -> String {
        for value in values {
            let trimmed = trim(value)
            if !trimmed.isEmpty { return trimmed }
        }
        return ""
    }

    nonisolated private static func trim(_ value: String?) -> String {
        (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func sparql(needle: String, limit: Int, offset: Int) -> String {
        let escaped = needle
            .lowercased()
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return """
        SELECT ?item ?itemLabel ?creatorLabel ?title ?accession ?image WHERE { \
        ?item wdt:P195 wd:\(pmaQID) . \
        ?item wdt:P18 ?image . \
        OPTIONAL { ?item wdt:P170 ?creator . } \
        OPTIONAL { ?item wdt:P1476 ?title . } \
        OPTIONAL { ?item wdt:P217 ?accession . } \
        FILTER(BOUND(?creator) || BOUND(?title)) \
        SERVICE wikibase:label { bd:serviceParam wikibase:language "en". } \
        FILTER(CONTAINS(LCASE(?itemLabel), "\(escaped)") || CONTAINS(LCASE(?creatorLabel), "\(escaped)") || CONTAINS(LCASE(STR(?title)), "\(escaped)")) \
        } LIMIT \(limit) OFFSET \(offset)
        """
    }

    private func send(_ request: URLRequest, retry: Bool = true) async throws -> Data {
        do {
            try Task.checkCancellation()
            let (data, response) = try await carrier.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw CatalogFault.transport
            }
            if http.statusCode == 404 {
                throw CatalogFault.missing
            }
            if http.statusCode == 401 || http.statusCode == 403 {
                throw CatalogFault.refused
            }
            guard (200 ..< 300).contains(http.statusCode) else {
                if retry {
                    return try await send(request, retry: false)
                }
                throw CatalogFault.transport
            }
            return data
        } catch is CancellationError {
            throw CatalogFault.cancelled
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw CatalogFault.cancelled
        } catch let fault as CatalogFault {
            throw fault
        } catch {
            if retry, Self.transient(error) {
                return try await send(request, retry: false)
            }
            throw CatalogFault.transport
        }
    }

    private static func transient(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet,
             .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }
}
