import UIKit

enum InstallHelper {
    static func canOpenAltStore() -> Bool {
        guard let url = URL(string: "altstore://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    static func altStoreInstallURL(ipaURL: URL) -> URL? {
        var components = URLComponents()
        components.scheme = "altstore"
        components.host = "install"
        components.queryItems = [
            URLQueryItem(name: "url", value: ipaURL.absoluteString)
        ]
        return components.url
    }

    @MainActor
    @discardableResult
    static func openInAltStore(ipaURL: URL) -> Bool {
        guard let url = altStoreInstallURL(ipaURL: ipaURL) else { return false }
        guard UIApplication.shared.canOpenURL(url) else { return false }
        UIApplication.shared.open(url)
        return true
    }

    @MainActor
    @discardableResult
    static func openHubPage(baseURL: URL, app: HubAppItem) -> Bool {
        guard let page = HubClient.webPageURL(baseURL: baseURL, app: app) else { return false }
        UIApplication.shared.open(page)
        return true
    }
}
