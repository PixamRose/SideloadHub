import Foundation

struct HubServerInfo: Codable, Sendable {
    let name: String
    let version: String
    let baseUrl: String
}

struct HubAppItem: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let name: String
    let bundleId: String
    let icon: String
    let accent: String
    let version: String
    let build: String
    let sizeBytes: Int
    let updatedAt: String
    let downloadPath: String
    let webPath: String
    let commit: String?
    let message: String?

    var sizeLabel: String {
        let mb = Double(sizeBytes) / 1_048_576
        return String(format: "%.1f Mo", mb)
    }

    var downloadURL: URL? {
        URL(string: downloadPath)
    }
}

struct HubCatalogResponse: Codable, Sendable {
    let server: HubServerInfo
    let apps: [HubAppItem]
}

struct HubHealthResponse: Codable, Sendable {
    let service: String
    let version: String
    let apps: Int
}

struct SavedHubServer: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    var host: String
    var port: Int
    var label: String
    var lastSeen: Date

    init(id: UUID = UUID(), host: String, port: Int = 8765, label: String = "Mon PC", lastSeen: Date = Date()) {
        self.id = id
        self.host = host
        self.port = port
        self.label = label
        self.lastSeen = lastSeen
    }

    var baseURL: URL? {
        URL(string: "http://\(host):\(port)/")
    }
}

enum DownloadState: String, Sendable {
    case idle
    case downloading
    case finished
    case failed
}

struct AppDownloadProgress: Identifiable, Sendable {
    let id: String
    var appName: String
    var progress: Double
    var state: DownloadState
    var localFileURL: URL?
    var errorMessage: String?
}
