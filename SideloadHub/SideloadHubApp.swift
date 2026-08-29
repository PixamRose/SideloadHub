import SwiftUI

@main
struct SideloadHubApp: App {
    @StateObject private var viewModel = HubViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .preferredColorScheme(.dark)
        }
    }
}
