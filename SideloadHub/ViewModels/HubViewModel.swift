import Foundation
import Network

@MainActor
final class HubViewModel: ObservableObject {
    @Published var hostInput = ""
    @Published var portInput = "8765"
    @Published var savedServers: [SavedHubServer] = []
    @Published var activeBaseURL: URL?
    @Published var catalog: HubCatalogResponse?
    @Published var isConnecting = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var selectedApp: HubAppItem?

    let downloadService = DownloadService()

    init() {
        savedServers = SavedHubStore.load()
        if let first = savedServers.first, let url = first.baseURL {
            hostInput = first.host
            portInput = String(first.port)
            Task { await connect(to: url, label: first.label) }
        }
    }

    func connectToInput() async {
        let host = hostInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let port = Int(portInput) ?? 8765
        guard !host.isEmpty, let url = URL(string: "http://\(host):\(port)/") else {
            errorMessage = "Adresse invalide"
            return
        }
        await connect(to: url, label: "Mon PC")
    }

    func connect(to baseURL: URL, label: String) async {
        isConnecting = true
        errorMessage = nil
        defer { isConnecting = false }

        do {
            _ = try await HubClient.health(baseURL: baseURL)
            let host = baseURL.host ?? ""
            let port = baseURL.port ?? 8765
            let saved = SavedHubStore.upsert(host: host, port: port, label: label)
            savedServers = SavedHubStore.load()
            activeBaseURL = baseURL
            hostInput = saved.host
            portInput = String(saved.port)
            await refreshCatalog()
        } catch {
            errorMessage = error.localizedDescription
            catalog = nil
            activeBaseURL = nil
        }
    }

    func refreshCatalog() async {
        guard let baseURL = activeBaseURL else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            catalog = try await HubClient.catalog(baseURL: baseURL)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func download(_ app: HubAppItem) {
        guard let baseURL = activeBaseURL,
              let url = HubClient.downloadURL(baseURL: baseURL, app: app) else {
            errorMessage = "URL de téléchargement invalide"
            return
        }
        downloadService.download(app: app, from: url)
    }

    func install(_ app: HubAppItem) {
        guard let baseURL = activeBaseURL,
              let ipaURL = HubClient.downloadURL(baseURL: baseURL, app: app) else {
            errorMessage = "URL de téléchargement invalide"
            return
        }

        if InstallHelper.openInAltStore(ipaURL: ipaURL) {
            errorMessage = nil
            return
        }

        if !InstallHelper.canOpenAltStore() {
            errorMessage = "AltStore requis : installe AltStore + AltServer sur le PC, puis reessaie."
            _ = InstallHelper.openHubPage(baseURL: baseURL, app: app)
        } else {
            errorMessage = "Impossible d ouvrir AltStore. Telechargement local lance."
        }

        download(app)
    }

    func markInstalled(_ app: HubAppItem) {
        SideloadTracker.recordInstall(bundleId: app.bundleId)
        objectWillChange.send()
    }

    func daysRemaining(for app: HubAppItem) -> Int? {
        SideloadTracker.daysRemaining(for: app.bundleId)
    }

    func expiryLabel(for app: HubAppItem) -> String {
        SideloadTracker.expiryLabel(for: app.bundleId)
    }
}
