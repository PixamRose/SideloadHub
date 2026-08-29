import SwiftUI

struct ConnectHubView: View {
    @EnvironmentObject private var viewModel: HubViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 48))
                        .foregroundStyle(HubTheme.accentGradient)
                    Text("SideloadHub")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("Connecte-toi au PC qui sert tes IPA sur le réseau local.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                HubGlassCard {
                    VStack(spacing: 12) {
                        TextField("IP du PC (ex: 192.168.1.42)", text: $viewModel.hostInput)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.decimalPad)
                            .padding(12)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        TextField("Port", text: $viewModel.portInput)
                            .keyboardType(.numberPad)
                            .padding(12)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button {
                            Task { await viewModel.connectToInput() }
                        } label: {
                            HStack {
                                if viewModel.isConnecting { ProgressView().tint(.black) }
                                Text(viewModel.isConnecting ? "Connexion…" : "Se connecter")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(HubTheme.accentGradient)
                            .foregroundStyle(.black.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(viewModel.isConnecting)
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.85))
                        .multilineTextAlignment(.center)
                }

                HubGlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Sur ton PC Windows", systemImage: "desktopcomputer")
                            .font(.headline)
                            .foregroundStyle(HubTheme.accent)
                        Text("1. Double-clique LAN-HUB.bat\n2. Note l'IP affichée\n3. Entre-la ici (port 8765)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !viewModel.savedServers.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Serveurs récents")
                            .font(.headline)
                        ForEach(viewModel.savedServers) { server in
                            Button {
                                if let url = server.baseURL {
                                    Task { await viewModel.connect(to: url, label: server.label) }
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(server.label).font(.headline)
                                        Text("\(server.host):\(server.port)").font(.caption).foregroundStyle(.white.opacity(0.55))
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.right.circle.fill")
                                }
                                .padding(14)
                                .background(HubTheme.cardFill)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}
