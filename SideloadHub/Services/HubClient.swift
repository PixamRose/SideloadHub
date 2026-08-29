import Foundation

enum HubClient {
    enum HubError: LocalizedError {
        case invalidURL
        case badResponse
        case notHub

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "URL invalide"
            case .badResponse: return "Réponse serveur invalide"
            case .notHub: return "Ce serveur n'est pas un SideloadHub"
            }
        }
    }

    static func health(baseURL: URL) async throws -> HubHealthResponse {
        let url = baseURL.appendingPathComponent("api/v1/health")
        var request = URLRequest(url: url)
        request.timeoutInterval = 4

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw HubError.badResponse
        }
        if http.value(forHTTPHeaderField: "X-SideloadHub") == nil {
            throw HubError.notHub
        }
        return try JSONDecoder().decode(HubHealthResponse.self, from: data)
    }

    static func catalog(baseURL: URL) async throws -> HubCatalogResponse {
        let url = baseURL.appendingPathComponent("api/v1/catalog")
        var request = URLRequest(url: url)
        request.timeoutInterval = 8

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw HubError.badResponse
        }
        return try JSONDecoder().decode(HubCatalogResponse.self, from: data)
    }

    static func downloadURL(baseURL: URL, app: HubAppItem) -> URL? {
        if app.downloadPath.hasPrefix("http") {
            return URL(string: app.downloadPath)
        }
        if app.downloadPath.hasPrefix("/") {
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
            components?.path = app.downloadPath
            return components?.url
        }
        return baseURL.appendingPathComponent(app.downloadPath)
    }
}
