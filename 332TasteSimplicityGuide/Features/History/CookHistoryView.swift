import SwiftUI

struct CookHistoryView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Group {
            if store.cookHistory.isEmpty {
                ScrollView {
                    LedgerEmptyState(
                        symbol: "clock.arrow.circlepath",
                        message: "Completed cooks will stamp this ledger with the plate and the time."
                    )
                    .padding(16)
                }
                .screenBackdrop()
            } else {
                List {
                    ForEach(store.cookHistory) { record in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(record.recipeName)
                                .font(.system(.headline, design: .serif))
                                .foregroundColor(Palette.ink)
                            Text("\(LedgerFormat.mediumDate.string(from: record.cookedAt)) · \(record.cookMinutes) min")
                                .font(.footnote.weight(.medium))
                                .foregroundColor(Palette.inkMuted)
                        }
                        .ledgerCard()
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .accessibilityIdentifier("history.row.\(record.id)")
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .screenBackdrop()
            }
        }
        .navigationTitle("Cook history")
        .navigationBarTitleDisplayMode(.inline)
    }
}
