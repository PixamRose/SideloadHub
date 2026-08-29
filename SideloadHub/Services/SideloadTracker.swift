import Foundation

enum SideloadTracker {
    private static let key = "sideloadhub.installDates"

    static func recordInstall(bundleId: String) {
        var map = loadMap()
        map[bundleId] = Date().timeIntervalSince1970
        saveMap(map)
    }

    static func installDate(for bundleId: String) -> Date? {
        guard let interval = loadMap()[bundleId] else { return nil }
        return Date(timeIntervalSince1970: interval)
    }

    static func daysRemaining(for bundleId: String, validityDays: Int = 7) -> Int? {
        guard let install = installDate(for: bundleId) else { return nil }
        let expiry = install.addingTimeInterval(TimeInterval(validityDays * 86_400))
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0
        return max(0, days)
    }

    static func expiryLabel(for bundleId: String) -> String {
        guard let days = daysRemaining(for: bundleId) else {
            return "Expiration non suivie"
        }
        if days == 0 { return "Expire aujourd'hui" }
        return "\(days) jour(s) restant(s)"
    }

    private static func loadMap() -> [String: TimeInterval] {
        UserDefaults.standard.dictionary(forKey: key) as? [String: TimeInterval] ?? [:]
    }

    private static func saveMap(_ map: [String: TimeInterval]) {
        UserDefaults.standard.set(map, forKey: key)
    }
}

enum SavedHubStore {
    private static let key = "sideloadhub.savedServers"

    static func load() -> [SavedHubServer] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let servers = try? JSONDecoder().decode([SavedHubServer].self, from: data) else {
            return []
        }
        return servers
    }

    static func save(_ servers: [SavedHubServer]) {
        guard let data = try? JSONEncoder().encode(servers) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func upsert(host: String, port: Int, label: String) -> SavedHubServer {
        var servers = load()
        if let index = servers.firstIndex(where: { $0.host == host && $0.port == port }) {
            servers[index].lastSeen = Date()
            servers[index].label = label
            save(servers)
            return servers[index]
        }
        let server = SavedHubServer(host: host, port: port, label: label)
        servers.insert(server, at: 0)
        save(servers)
        return server
    }
}
