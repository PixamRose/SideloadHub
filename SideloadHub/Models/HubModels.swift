import Foundation

struct HubServerInfo: Codable, Sendable {
    let name: String
    let version: String
    let baseUrl: String
}

struct HubAppItem: Decodable, Identifiable, Sendable, Equatable {
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

    enum CodingKeys: String, CodingKey {
        case id, name, bundleId, icon, accent, version, build, sizeBytes
        case updatedAt, downloadPath, webPath, commit, message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        bundleId = try container.decode(String.self, forKey: .bundleId)
        icon = try container.decode(String.self, forKey: .icon)
        accent = try container.decode(String.self, forKey: .accent)
        version = try container.decodeIfPresent(String.self, forKey: .version) ?? "?"
        build = try container.decodeIfPresent(String.self, forKey: .build) ?? "?"
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt) ?? ""
        downloadPath = try container.decode(String.self, forKey: .downloadPath)
        webPath = try container.decodeIfPresent(String.self, forKey: .webPath) ?? ""
        commit = try container.decodeIfPresent(String.self, forKey: .commit)
        message = try container.decodeIfPresent(String.self, forKey: .message)

        if let intSize = try? container.decode(Int.self, forKey: .sizeBytes) {
            sizeBytes = intSize
        } else if let doubleSize = try? container.decode(Double.self, forKey: .sizeBytes) {
            sizeBytes = Int(doubleSize)
        } else if let stringSize = try? container.decode(String.self, forKey: .sizeBytes),
                  let parsed = Int(stringSize) {
            sizeBytes = parsed
        } else {
            sizeBytes = 0
        }
    }

    static func == (lhs: HubAppItem, rhs: HubAppItem) -> Bool {
        lhs.id == rhs.id
    }

    var sizeLabel: String {
        let mb = Double(sizeBytes) / 1_048_576
        return String(format: "%.1f Mo", mb)
    }

    var downloadURL: URL? {
        URL(string: downloadPath)
    }
}

struct HubCatalogResponse: Decodable, Sendable {
    let server: HubServerInfo
    let apps: [HubAppItem]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        server = try container.decode(HubServerInfo.self, forKey: .server)

        if let list = try? container.decode([HubAppItem].self, forKey: .apps) {
            apps = list
        } else if let single = try? container.decode(HubAppItem.self, forKey: .apps) {
            apps = [single]
        } else {
            apps = []
        }
    }

    private enum CodingKeys: String, CodingKey {
        case server, apps
    }
}

struct HubHealthResponse: Decodable, Sendable {
    let service: String
    let version: String
    let apps: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        service = try container.decode(String.self, forKey: .service)
        version = try container.decode(String.self, forKey: .version)

        if let count = try? container.decode(Int.self, forKey: .apps) {
            apps = count
        } else if let countString = try? container.decode(String.self, forKey: .apps),
                  let parsed = Int(countString) {
            apps = parsed
        } else {
            apps = 0
        }
    }

    private enum CodingKeys: String, CodingKey {
        case service, version, apps
    }
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
