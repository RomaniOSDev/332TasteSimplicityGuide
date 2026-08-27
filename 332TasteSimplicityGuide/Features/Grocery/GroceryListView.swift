import SwiftUI

struct GroceryListView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showAdd = false
    @State private var editingItem: GroceryItem?
    @State private var pendingDelete: GroceryItem?

    var body: some View {
        Group {
            if store.groceryItems.isEmpty {
                ScrollView {
                    VStack(spacing: 16) {
                        WorkshopBanner(
                            imageName: "bannerPantry",
                            title: "Market list",
                            subtitle: "Missing pieces from planned cooks land here."
                        )
                        LedgerEmptyState(
                            symbol: "cart",
                            message: "Nothing to fetch yet. Add an item or plan a cook."
                        )
                        if !store.lastMarketTrip.isEmpty {
                            Button {
                                store.repeatLastMarketTrip()
                                Haptics.success()
                            } label: {
                                Label("Repeat last trip", systemImage: "arrow.clockwise")
                            }
                            .buttonStyle(HerbStampButtonStyle())
                            .frame(maxWidth: .infinity)
                            .accessibilityIdentifier("grocery.repeat")
                        }
                        Button {
                            showAdd = true
                        } label: {
                            Label("Add market item", systemImage: "plus")
                        }
                        .buttonStyle(HerbGradientButtonStyle())
                        .accessibilityIdentifier("grocery.add.empty")
                    }
                    .padding(16)
                }
                .screenBackdrop()
            } else {
                List {
                    if !store.lastMarketTrip.isEmpty {
                        Button {
                            store.repeatLastMarketTrip()
                            Haptics.success()
                        } label: {
                            Label("Repeat last trip", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(HerbStampButtonStyle())
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .accessibilityIdentifier("grocery.repeat")
                    }
                    if store.groceryItems.contains(where: \.acquired) {
                        Button {
                            store.restockAllAcquired()
                            Haptics.success()
                        } label: {
                            Label("Move acquired to pantry", systemImage: "cabinet.fill")
                        }
                        .buttonStyle(HerbGradientButtonStyle())
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .accessibilityIdentifier("grocery.restockAll")
                    }
                    ForEach(groupedMarket, id: \.category) { group in
                        Section {
                            ForEach(group.items) { item in
                                groceryRow(item)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button {
                                            store.toggleAcquired(id: item.id)
                                            Haptics.light()
                                        } label: {
                                            Label(item.acquired ? "Undo" : "Got it", systemImage: "checkmark")
                                        }
                                        .tint(Color("AppAccent"))
                                        .accessibilityIdentifier("grocery.swipeAcquire.\(item.id)")
                                        Button(role: .destructive) {
                                            pendingDelete = item
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        .accessibilityIdentifier("grocery.swipeDelete.\(item.id)")
                                    }
                            }
                        } header: {
                            Text(group.category.uppercased())
                                .font(.system(.caption, design: .serif).weight(.bold))
                                .foregroundColor(Palette.onDark)
                                .padding(.horizontal, 4)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .screenBackdrop()
            }
        }
        .navigationTitle("Market")
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
                .accessibilityIdentifier("grocery.add")
            }
            ToolbarItem(placement: .navigationBarLeading) {
                ShareLink(item: shareLines.joined(separator: "\n")) {
                    Image(systemName: "square.and.arrow.up")
                        .frame(width: 44, height: 44)
                        .foregroundColor(Palette.onDark)
                }
                .disabled(store.groceryItems.isEmpty)
                .accessibilityIdentifier("grocery.share")
            }
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                GroceryEditorView(existing: nil)
                    .keyboardDoneAccessory()
            }
            .environmentObject(store)
        }
        .sheet(item: $editingItem) { item in
            NavigationStack {
                GroceryEditorView(existing: item)
                    .keyboardDoneAccessory()
            }
            .environmentObject(store)
        }
        .alert("Remove this item?", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingDelete = nil }
                .accessibilityIdentifier("grocery.delete.cancel")
            Button("Delete", role: .destructive) {
                if let item = pendingDelete {
                    store.deleteGrocery(id: item.id)
                }
                pendingDelete = nil
            }
            .accessibilityIdentifier("grocery.delete.confirm")
        }
    }

    private var groupedMarket: [(category: String, items: [GroceryItem])] {
        let grouped = Dictionary(grouping: store.sortedGroceryItems, by: \.category)
        return grouped.keys.sorted().map { key in
            (category: key, items: grouped[key] ?? [])
        }
    }

    private var shareLines: [String] {
        store.sortedGroceryItems.map { item in
            let mark = item.acquired ? "✓" : "○"
            return "\(mark) \(LedgerFormat.quantity(item.quantity)) \(item.name)"
        }
    }

    private func groceryRow(_ item: GroceryItem) -> some View {
        HStack(spacing: 12) {
            Button {
                store.toggleAcquired(id: item.id)
                Haptics.light()
            } label: {
                Image(systemName: item.acquired ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(item.acquired ? Color("AppPrimary") : Palette.ink)
                    .frame(width: 44, height: 44)
            }
            .accessibilityIdentifier("grocery.toggle.\(item.id)")

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(.headline, design: .serif))
                    .strikethrough(item.acquired)
                    .foregroundColor(Palette.ink.opacity(item.acquired ? 0.55 : 1))
                Text("\(item.category) · \(LedgerFormat.quantity(item.quantity))")
                    .font(.footnote.weight(.medium))
                    .foregroundColor(Palette.inkMuted)
            }
            Spacer()
            if item.acquired {
                Button {
                    store.restockGroceryToPantry(id: item.id)
                    Haptics.success()
                } label: {
                    Image(systemName: "cabinet.fill")
                        .frame(width: 44, height: 44)
                        .foregroundColor(Color("AppPrimary"))
                }
                .accessibilityIdentifier("grocery.restock.\(item.id)")
            }
            Button {
                editingItem = item
            } label: {
                Image(systemName: "pencil")
                    .frame(width: 44, height: 44)
                    .foregroundColor(Color("AppPrimary"))
            }
            .accessibilityIdentifier("grocery.edit.\(item.id)")
        }
        .ledgerCard()
        .accessibilityIdentifier("grocery.row.\(item.id)")
    }
}
