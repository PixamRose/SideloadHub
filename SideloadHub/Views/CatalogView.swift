import SwiftUI

struct CatalogView: View {
    @EnvironmentObject private var viewModel: HubViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let server = viewModel.catalog?.server {
                    HubGlassCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(server.name).font(.headline)
                                Text("v\(server.version) · \(viewModel.catalog?.apps.count ?? 0) app(s)")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.55))
                            }
                            Spacer()
                            Button {
                                Task { await viewModel.refreshCatalog() }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title3)
                                    .foregroundStyle(HubTheme.accent)
                                    .rotationEffect(.degrees(viewModel.isRefreshing ? 360 : 0))
                                    .animation(viewModel.isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isRefreshing)
                            }
                        }
                    }
                }

                if let apps = viewModel.catalog?.apps, !apps.isEmpty {
                    ForEach(apps) { app in
                        AppCatalogCard(app: app)
                    }
                } else {
                    HubGlassCard {
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.largeTitle)
                                .foregroundStyle(HubTheme.accent.opacity(0.7))
                            Text("Aucune app sur le hub")
                                .font(.headline)
                            Text("Lance SYNC-HUB.bat sur le PC ou vérifie le token GitHub.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.55))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(20)
        }
        .refreshable { await viewModel.refreshCatalog() }
        .sheet(item: $viewModel.selectedApp) { app in
            AppDetailSheet(app: app)
        }
    }
}

struct AppCatalogCard: View {
    @EnvironmentObject private var viewModel: HubViewModel
    let app: HubAppItem

    private var download: AppDownloadProgress? {
        viewModel.downloadService.downloads[app.id]
    }

    var body: some View {
        Button {
            viewModel.selectedApp = app
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(HubTheme.color(from: app.accent).opacity(0.18))
                        .frame(width: 52, height: 52)
                    Image(systemName: app.icon)
                        .foregroundStyle(HubTheme.color(from: app.accent))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name).font(.headline).foregroundStyle(.white)
                    Text("v\(app.version) · \(app.sizeLabel)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                    Text(viewModel.expiryLabel(for: app))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(expiryColor)
                }

                Spacer()

                if let download, download.state == .downloading {
                    ProgressView(value: download.progress)
                        .frame(width: 36)
                } else if download?.state == .finished {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(HubTheme.success)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(HubTheme.cardFill)
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(HubTheme.cardStroke, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }

    private var expiryColor: Color {
        guard let days = viewModel.daysRemaining(for: app) else { return .white.opacity(0.45) }
        if days <= 1 { return HubTheme.warning }
        if days <= 3 { return HubTheme.warning.opacity(0.85) }
        return HubTheme.success
    }
}
