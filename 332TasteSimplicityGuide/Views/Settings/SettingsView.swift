import SwiftUI
import StoreKit
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Workshop")
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .foregroundColor(Palette.onDark)

                Text("Ledger tools for this kitchen.")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Palette.onDarkMuted)

                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: Binding(
                        get: { store.activeNotifications },
                        set: { store.setActiveNotifications($0) }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Timer completion banners")
                                .font(.system(.headline, design: .serif))
                                .foregroundColor(Palette.ink)
                            Text("In-app visual stamps only. No system alerts.")
                                .font(.footnote.weight(.medium))
                                .foregroundColor(Palette.inkMuted)
                        }
                    }
                    .tint(Color("AppAccent"))
                    .accessibilityIdentifier("settings.alerts")
                    .frame(minHeight: 44)
                }
                .ledgerCard()

                VStack(spacing: 10) {
                    Button {
                        rateApp()
                    } label: {
                        settingsRow(symbol: "star.fill", title: "Rate Us")
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("settings.rate")

                    Button {
                        if let url = URL(string: AppLinks.privacy) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        settingsRow(symbol: "hand.raised.fill", title: "Privacy")
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("settings.privacy")

                    Button {
                        if let url = URL(string: AppLinks.terms) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        settingsRow(symbol: "doc.plaintext.fill", title: "Terms")
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("settings.terms")
                }

                Button {
                    confirmReset = true
                } label: {
                    Label("Reset All Data", systemImage: "trash.fill")
                }
                .buttonStyle(HerbStampButtonStyle())
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("settings.reset")

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(HerbGradientButtonStyle())
                .accessibilityIdentifier("settings.done")
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .screenBackdrop()
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reset All Data?", isPresented: $confirmReset) {
            Button("Cancel", role: .cancel) {}
                .accessibilityIdentifier("settings.reset.cancel")
            Button("Reset All Data", role: .destructive) {
                store.resetAllData()
            }
            .accessibilityIdentifier("settings.reset.confirm")
        } message: {
            Text("This clears pantry, grocery list, timers, planned meals, favorites, and cook history on this device.")
        }
    }

    private func settingsRow(symbol: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color("AppPrimary"))
                .frame(width: 32, height: 32)
            Text(title)
                .font(.system(.headline, design: .serif))
                .foregroundColor(Palette.ink)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(Palette.ink.opacity(0.35))
        }
        .frame(minHeight: 44)
        .ledgerCard()
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
