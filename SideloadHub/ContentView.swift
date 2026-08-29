import SwiftUI

struct MainHubView: View {
    @EnvironmentObject private var viewModel: HubViewModel

    var body: some View {
        TabView {
            CatalogView()
                .tabItem { Label("Apps", systemImage: "square.grid.2x2.fill") }

            ConnectHubView()
                .tabItem { Label("Hub", systemImage: "server.rack") }
        }
        .tint(HubTheme.accent)
    }
}

struct ContentView: View {
    @EnvironmentObject private var viewModel: HubViewModel

    var body: some View {
        Group {
            if viewModel.activeBaseURL != nil, viewModel.catalog != nil {
                MainHubView()
            } else {
                ConnectHubView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HubViewModel())
}
