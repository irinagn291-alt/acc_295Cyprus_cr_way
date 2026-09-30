import SwiftUI
import UIKit

/// Role: Work. Local face cache for Commons thumbs. User-Agent on every hop. Views never talk to URLSession.
@MainActor
@Observable
final class CanvasFace {
    static let shared = CanvasFace()

    private var pictures: [String: Image] = [:]
    private var inflight: [String: Task<Void, Never>] = [:]
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = CatalogClient.timeout
        configuration.timeoutIntervalForResource = CatalogClient.timeout
        configuration.httpAdditionalHeaders = ["User-Agent": CatalogClient.userAgent]
        session = URLSession(configuration: configuration)
    }

    func picture(for url: URL?) -> Image? {
        guard let url else { return nil }
        return pictures[url.absoluteString]
    }

    func load(_ url: URL?) async {
        guard let url else { return }
        let key = url.absoluteString
        if pictures[key] != nil { return }
        if inflight[key] != nil {
            await inflight[key]?.value
            return
        }
        let task = Task { [session] in
            var request = URLRequest(url: url, timeoutInterval: CatalogClient.timeout)
            request.setValue(CatalogClient.userAgent, forHTTPHeaderField: "User-Agent")
            guard let (data, response) = try? await session.data(for: request) else { return }
            guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
                return
            }
            if let ui = UIImage(data: data) {
                pictures[key] = Image(uiImage: ui)
            }
        }
        inflight[key] = task
        await task.value
        inflight[key] = nil
    }

    func loadMany(_ urls: [URL?]) async {
        await withTaskGroup(of: Void.self) { group in
            var seen = Set<String>()
            for url in urls {
                guard let url, seen.insert(url.absoluteString).inserted else { continue }
                group.addTask { await self.load(url) }
            }
        }
    }

    func loadWork(_ work: Work) async {
        await loadMany(Self.imageURLs(for: work))
    }

    func picture(for work: Work) -> Image? {
        for url in Self.imageURLs(for: work) {
            if let face = picture(for: url) {
                return face
            }
        }
        return nil
    }

    func picture(for row: CatalogRow) -> Image? {
        for url in Self.imageURLs(for: row) {
            if let face = picture(for: url) {
                return face
            }
        }
        return nil
    }

    static func imageURLs(for work: Work) -> [URL?] {
        let shelf = PmaShelf.bundled.rows.first { $0.objectID == work.objectID }
        let shelfURL = shelf?.imageURL
        let script = CatalogClient.thumbScriptURL(from: shelf?.imageURLString ?? work.imageURLString)
        return [shelfURL, work.imageURL, script]
    }

    static func imageURLs(for row: CatalogRow) -> [URL?] {
        [row.imageURL, CatalogClient.thumbScriptURL(from: row.imageURLString)]
    }
}
