import SwiftUI

enum Palette {
    static let bg = Color("AppBackground")
    static let surface = Color("AppSurface")
    static let primary = Color("AppPrimary")
    static let accent = Color("AppAccent")

    /// Paper card fill — high contrast against the dark kitchen backdrop.
    static let card = Color(red: 0.96, green: 0.94, blue: 0.88)
    /// Dark ink on paper cards.
    static let ink = Color(red: 0.11, green: 0.13, blue: 0.20)
    static let inkMuted = Color(red: 0.11, green: 0.13, blue: 0.20).opacity(0.78)
    /// Titles and tab labels sitting on the dark backdrop.
    static let onDark = Color(red: 0.98, green: 0.97, blue: 0.93)
    static let onDarkMuted = Color(red: 0.98, green: 0.97, blue: 0.93).opacity(0.78)
}

struct RailCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 0) {
            LinearGradient(
                colors: [Palette.primary, Palette.accent],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: 6)
            content
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Palette.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.32), radius: 10, x: 0, y: 7)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
        )
    }
}

struct GlowButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Palette.primary, Palette.accent],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: Palette.primary.opacity(0.45), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}
