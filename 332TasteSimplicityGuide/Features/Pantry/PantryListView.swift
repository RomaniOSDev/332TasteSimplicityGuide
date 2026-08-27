import SwiftUI

struct PantryListView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showAdd = false
    @State private var editingItem: PantryItem?
    @State private var pendingDelete: PantryItem?

    var body: some View {
        Group {
            if store.pantryItems.isEmpty {
                ScrollView {
                    VStack(spacing: 16) {
                        LedgerEmptyState(
                            symbol: "cabinet.fill",
                            message: "Your pantry is empty. Add ingredients so recipes can match what you already have."
                        )
                        Button {
                            showAdd = true
                        } label: {
                            Label("Add pantry item", systemImage: "plus")
                        }
                        .buttonStyle(HerbGradientButtonStyle())
                        .accessibilityIdentifier("pantry.add.empty")
                    }
                    .padding(16)
                }
                .screenBackdrop()
            } else {
                List {
                    ForEach(sortedItems) { item in
                        pantryRow(item)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    store.sendPantryToMarket(item)
                                    Haptics.light()
                                } label: {
                                    Label("Market", systemImage: "cart.fill")
                                }
                                .tint(Color("AppAccent"))
                                .accessibilityIdentifier("pantry.swipeMarket.\(item.id)")
                                Button(role: .destructive) {
                                    pendingDelete = item
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .accessibilityIdentifier("pantry.swipeDelete.\(item.id)")
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .screenBackdrop()
            }
        }
        .navigationTitle("Pantry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 44, height: 44)
                        .foregroundColor(Palette.onDark)
                }
                .accessibilityIdentifier("pantry.add")
            }
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                PantryEditorView(existing: nil)
                    .keyboardDoneAccessory()
            }
            .environmentObject(store)
        }
        .sheet(item: $editingItem) { item in
            NavigationStack {
                PantryEditorView(existing: item)
                    .keyboardDoneAccessory()
            }
            .environmentObject(store)
        }
        .alert("Remove this ingredient?", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                pendingDelete = nil
            }
            .accessibilityIdentifier("pantry.delete.cancel")
            Button("Delete", role: .destructive) {
                if let item = pendingDelete {
                    store.deletePantry(id: item.id)
                    Haptics.warning()
                }
                pendingDelete = nil
            }
            .accessibilityIdentifier("pantry.delete.confirm")
        } message: {
            Text("This item will leave the pantry ledger.")
        }
    }

    private var sortedItems: [PantryItem] {
        store.pantryItems.sorted {
            let leftEat = $0.isEatFirst
            let rightEat = $1.isEatFirst
            if leftEat != rightEat { return leftEat && !rightEat }
            if leftEat, rightEat {
                return ($0.expiresAt ?? .distantFuture) < ($1.expiresAt ?? .distantFuture)
            }
            let leftLow = $0.quantity <= 1
            let rightLow = $1.quantity <= 1
            if leftLow != rightLow { return leftLow && !rightLow }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private func pantryRow(_ item: PantryItem) -> some View {
        let low = item.quantity <= 1
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(.headline, design: .serif))
                    .foregroundColor(Palette.ink)
                Text("\(item.category) · \(LedgerFormat.quantity(item.quantity)) \(item.unit)")
                    .font(.footnote.weight(.medium))
                    .foregroundColor(Palette.inkMuted)
                if let stamp = expiryStamp(item) {
                    Text(stamp)
                        .font(.caption.weight(.bold))
                        .foregroundColor(Color("AppPrimary"))
                } else if low {
                    Text(item.quantity <= 0 ? "Empty" : "Running low")
                        .font(.caption.weight(.bold))
                        .foregroundColor(Color("AppPrimary"))
                }
            }
            Spacer()
            Button {
                store.sendPantryToMarket(item)
                Haptics.light()
            } label: {
                Image(systemName: "cart.fill")
                    .frame(width: 44, height: 44)
                    .foregroundColor(Color("AppPrimary"))
            }
            .accessibilityIdentifier("pantry.market.\(item.id)")
            Button {
                editingItem = item
            } label: {
                Image(systemName: "pencil")
                    .frame(width: 44, height: 44)
                    .foregroundColor(Color("AppPrimary"))
            }
            .accessibilityIdentifier("pantry.edit.\(item.id)")
            Button {
                pendingDelete = item
            } label: {
                Image(systemName: "trash")
                    .frame(width: 44, height: 44)
                    .foregroundColor(Palette.ink)
            }
            .accessibilityIdentifier("pantry.delete.\(item.id)")
        }
        .ledgerCard()
        .accessibilityIdentifier("pantry.row.\(item.id)")
    }

    private func expiryStamp(_ item: PantryItem) -> String? {
        guard let days = item.daysUntilExpiry() else { return nil }
        if days < 0 { return "Expired · eat or toss" }
        if days == 0 { return "Eat today" }
        if days == 1 { return "Eat tomorrow" }
        if days <= 3 { return "Eat in \(days) days" }
        return "Use by \(LedgerFormat.mediumDate.string(from: item.expiresAt ?? Date()))"
    }
}
