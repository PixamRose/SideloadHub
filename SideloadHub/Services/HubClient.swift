import Foundation

enum HubClient {
    enum HubError: LocalizedError {
        case invalidURL
        case badResponse
        case notHub
        case decodeFailed(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "URL invalide"
            case .badResponse: return "Réponse serveur invalide"
            case .notHub: return "Ce serveur n'est pas un SideloadHub"
            case .decodeFailed(let detail): return "Format JSON incorrect: \(detail)"
            }
        }
    }

    private static func endpointURL(baseURL: URL, path: String) -> URL? {
        var base = baseURL.absoluteString
        if !base.hasSuffix("/") { base += "/" }
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return URL(string: base + cleanPath)
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            let preview = String(data: data.prefix(180), encoding: .utf8) ?? "?"
            throw HubError.decodeFailed("\(error.localizedDescription) | \(preview)")
        }
    }

    static func health(baseURL: URL) async throws -> HubHealthResponse {
        guard let url = endpointURL(baseURL: baseURL, path: "api/v1/health") else {
            throw HubError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 4

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw HubError.badResponse
        }
        if http.value(forHTTPHeaderField: "X-SideloadHub") == nil {
            throw HubError.notHub
        }
        return try decode(HubHealthResponse.self, from: data)
    }

    static func catalog(baseURL: URL) async throws -> HubCatalogResponse {
        guard let url = endpointURL(baseURL: baseURL, path: "api/v1/catalog") else {
            throw HubError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 8

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw HubError.badResponse
        }
        return try decode(HubCatalogResponse.self, from: data)
    }

    static func downloadURL(baseURL: URL, app: HubAppItem) -> URL? {
        if app.downloadPath.hasPrefix("http") {
            return URL(string: app.downloadPath)
        }
        return endpointURL(baseURL: baseURL, path: app.downloadPath)
    }
}
