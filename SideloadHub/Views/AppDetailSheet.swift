import SwiftUI

struct AppDetailSheet: View {
    @EnvironmentObject private var viewModel: HubViewModel
    @Environment(\.dismiss) private var dismiss
    let app: HubAppItem

    @State private var showShare = false

    private var download: AppDownloadProgress? {
        viewModel.downloadService.downloads[app.id]
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
                                if let message = app.message {
                                    Text(message)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.45))
                                        .lineLimit(3)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        HubGlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Expiration sideload")
                                    .font(.headline)
                                Text(viewModel.expiryLabel(for: app))
                                    .foregroundStyle(HubTheme.warning)
                                Button("Marquer comme installée aujourd'hui") {
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
                                        Text("\(Int(download.progress * 100))%")
                                            .font(.caption)
                                    case .finished:
                                        Label("Téléchargement terminé", systemImage: "checkmark.circle.fill")
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
                            viewModel.download(app)
                        } label: {
                            Label("Télécharger l'IPA", systemImage: "arrow.down.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(HubTheme.accentGradient)
                                .foregroundStyle(.black.opacity(0.85))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        if download?.state == .finished, let url = download?.localFileURL {
                            ShareLink(item: url, preview: SharePreview(app.name, image: Image(systemName: app.icon))) {
                                Label("Partager / Ouvrir avec AltStore", systemImage: "square.and.arrow.up")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.white.opacity(0.10))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            Button {
                                viewModel.markInstalled(app)
                            } label: {
                                Label("J'ai installé — reset 7 jours", systemImage: "calendar.badge.clock")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .foregroundStyle(HubTheme.success)
                        }

                        HubGlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Installation")
                                    .font(.headline)
                                Text("1. Télécharge l'IPA\n2. Partage → AltStore (si AltServer tourne sur le PC)\n3. Ou ouvre Safari sur le PC hub pour Sideloadly WiFi/USB")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.55))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Mise à jour")
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
