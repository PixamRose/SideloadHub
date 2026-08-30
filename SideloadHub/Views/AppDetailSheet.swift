import SwiftUI

struct AppDetailSheet: View {
    @EnvironmentObject private var viewModel: HubViewModel
    @Environment(\.dismiss) private var dismiss
    let app: HubAppItem

    private var download: AppDownloadProgress? {
        viewModel.downloadService.downloads[app.id]
    }

    private var hasAltStore: Bool {
        InstallHelper.canOpenAltStore()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HubBackground()
                ScrollView {
                    VStack(spacing: 18) {
                        HubGlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: app.icon)
                                        .font(.title2)
                                        .foregroundStyle(HubTheme.color(from: app.accent))
                                    Text(app.name)
                                        .font(.title2.bold())
                                }
                                Text("Version \(app.version) (build \(app.build))")
                                    .foregroundStyle(.white.opacity(0.65))
                                Text(app.sizeLabel)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.45))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        HubGlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Expiration sideload")
                                    .font(.headline)
                                Text(viewModel.expiryLabel(for: app))
                                    .foregroundStyle(HubTheme.warning)
                                Button("Marquer comme installee aujourd hui") {
                                    viewModel.markInstalled(app)
                                }
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(HubTheme.accent)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if let download {
                            HubGlassCard {
                                VStack(spacing: 10) {
                                    switch download.state {
                                    case .downloading:
                                        ProgressView(value: download.progress)
                                        Text("Telechargement secours \(Int(download.progress * 100))%")
                                            .font(.caption)
                                    case .finished:
                                        Label("Copie locale prete", systemImage: "checkmark.circle.fill")
                                            .foregroundStyle(HubTheme.success)
                                    case .failed:
                                        Text(download.errorMessage ?? "Erreur")
                                            .foregroundStyle(.red)
                                    case .idle:
                                        EmptyView()
                                    }
                                }
                            }
                        }

                        Button {
                            viewModel.install(app)
                        } label: {
                            Label(
                                hasAltStore ? "Mettre a jour (AltStore)" : "Installer",
                                systemImage: "arrow.down.app.fill"
                            )
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(HubTheme.accentGradient)
                            .foregroundStyle(.black.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        if download?.state == .finished, let url = download?.localFileURL {
                            ShareLink(item: url, preview: SharePreview(app.name, image: Image(systemName: app.icon))) {
                                Label("Partager IPA (Sideloadly)", systemImage: "square.and.arrow.up")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.white.opacity(0.10))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }

                        HubGlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Installation auto")
                                    .font(.headline)
                                if hasAltStore {
                                    Text("1. AltServer doit tourner sur ton PC (icone barre des taches)\n2. Appuie sur Mettre a jour\n3. AltStore telecharge depuis le hub LAN et installe")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.55))
                                } else {
                                    Text("Installe AltStore sur iPhone + AltServer sur Windows pour installer en 1 tap depuis le reseau local.")
                                        .font(.caption)
                                        .foregroundStyle(HubTheme.warning.opacity(0.9))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Mise a jour")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                        .foregroundStyle(HubTheme.accent)
                }
            }
        }
    }
}
