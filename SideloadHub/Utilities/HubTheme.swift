import SwiftUI

enum HubTheme {
    static let backgroundTop = Color(red: 0.05, green: 0.03, blue: 0.12)
    static let backgroundBottom = Color(red: 0.12, green: 0.06, blue: 0.20)
    static let accent = Color(red: 0.85, green: 0.35, blue: 1.0)
    static let accentSecondary = Color(red: 0.45, green: 0.55, blue: 1.0)
    static let success = Color(red: 0.30, green: 0.95, blue: 0.55)
    static let warning = Color(red: 1.0, green: 0.72, blue: 0.25)
    static let cardFill = Color.white.opacity(0.06)
    static let cardStroke = Color.white.opacity(0.12)

    static var backgroundGradient: LinearGradient {
        LinearGradient(colors: [backgroundTop, backgroundBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var accentGradient: LinearGradient {
        LinearGradient(colors: [accent, accentSecondary], startPoint: .leading, endPoint: .trailing)
    }

    static func color(from hex: String) -> Color {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else { return accent }
        return Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

struct HubBackground: View {
    var body: some View {
        ZStack {
            HubTheme.backgroundGradient
            Circle().fill(HubTheme.accent.opacity(0.10)).frame(width: 280).blur(radius: 60).offset(x: 120, y: -180)
        }
        .ignoresSafeArea()
    }
}

struct HubGlassCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(HubTheme.cardFill)
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(HubTheme.cardStroke, lineWidth: 1))
            )
    }
}
