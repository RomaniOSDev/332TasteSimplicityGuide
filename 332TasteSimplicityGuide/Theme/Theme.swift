import SwiftUI
import UIKit

enum Keyboard {
    static func dismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

enum ThemeChrome {
    static func apply() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        let titleColor = UIColor(red: 0.98, green: 0.97, blue: 0.93, alpha: 1)
        appearance.titleTextAttributes = [
            .foregroundColor: titleColor
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: titleColor
        ]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(named: "AppAccent") ?? UIColor(red: 0.35, green: 0.73, blue: 0.46, alpha: 1)
        UINavigationBar.appearance().barTintColor = UIColor(named: "AppBackground")

        let field = UITextField.appearance()
        field.tintColor = UIColor(named: "AppAccent")
    }
}

enum LedgerFormat {
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let shortWeekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EE")
        return formatter
    }()

    static let weekdayDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEE d")
        return formatter
    }()

    static func quantity(_ value: Double) -> String {
        if abs(value - value.rounded()) < 0.0001 {
            return String(Int(value.rounded()))
        }
        return String(format: "%.1f", value)
    }
}

extension View {
    func screenBackdrop() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color("AppBackground").overlay {
                    Image("bgKitchen")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.16)
                }
                .overlay(Color.black.opacity(0.28))
                .clipped()
                .ignoresSafeArea()
            }
    }

    func ledgerCard() -> some View {
        RailCard { self }
    }

    func keyboardDoneAccessory() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    Keyboard.dismiss()
                }
                .font(.headline)
                .foregroundColor(Color("AppAccent"))
                .accessibilityIdentifier("keyboard.done")
            }
        }
    }
}

struct HerbGradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .serif))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, 8)
            .background(
                LinearGradient(
                    colors: [Color("AppPrimary"), Color("AppAccent")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .opacity(configuration.isPressed ? 0.82 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color("AppPrimary").opacity(0.38), radius: 8, y: 4)
    }
}

struct HerbStampButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .serif))
            .foregroundColor(Color("AppPrimary"))
            .frame(minWidth: 44, minHeight: 44)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Palette.card)
                    .shadow(color: Color.black.opacity(0.18), radius: 6, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color("AppPrimary").opacity(0.7), lineWidth: 1.5)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct SectionStamp: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.system(.caption, design: .serif).weight(.heavy))
            .tracking(1.4)
            .foregroundColor(Color("AppPrimary"))
    }
}

struct WorkshopBanner: View {
    let imageName: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.title, design: .serif).weight(.bold))
                .foregroundColor(Palette.onDark)
            Text(subtitle)
                .font(.system(.subheadline, design: .serif).weight(.medium))
                .foregroundColor(Palette.onDark)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 148, alignment: .bottomLeading)
        .background {
            Color("AppBackground").overlay {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            .overlay {
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.15),
                        Color.black.opacity(0.72)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.28), radius: 12, y: 8)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct LedgerEmptyState: View {
    let symbol: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 44, weight: .light))
                .foregroundColor(Color("AppPrimary"))
            Text(message)
                .font(.system(.body, design: .serif).weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundColor(Palette.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .ledgerCard()
    }
}

struct LedgerTextField: View {
    let title: String
    let identifier: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(.caption, design: .serif).weight(.bold))
                .foregroundColor(Color("AppPrimary"))
            TextField(title, text: $text)
                .keyboardType(keyboard)
                .foregroundColor(Palette.ink)
                .tint(Color("AppAccent"))
                .frame(minHeight: 44)
                .padding(.horizontal, 12)
                .background(Color.white.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Palette.ink.opacity(0.18), lineWidth: 1)
                )
                .accessibilityIdentifier(identifier)
        }
    }
}

struct FieldErrorText: View {
    let message: String
    let identifier: String

    var body: some View {
        if !message.isEmpty {
            Text(message)
                .font(.footnote.weight(.semibold))
                .foregroundColor(Color(red: 0.72, green: 0.18, blue: 0.16))
                .accessibilityIdentifier(identifier)
        }
    }
}
