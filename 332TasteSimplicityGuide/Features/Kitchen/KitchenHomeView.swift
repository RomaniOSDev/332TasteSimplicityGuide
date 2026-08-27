import SwiftUI

struct KitchenHomeView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showAddPantry = false
    @State private var pendingComplete: PlannedMeal?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                WorkshopBanner(
                    imageName: "bannerPantry",
                    title: "Herb Workshop",
                    subtitle: "Stock the ledger, then cook from what you have."
                )

                pantrySummary
                eatFirstCard
                tonightCard
                lowStockCard
                weekStrip
                plannedSection
                historyShortcut
            }
            .padding(16)
            .padding(.bottom, 28)
        }
        .screenBackdrop()
        .navigationTitle("Kitchen")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddPantry) {
            NavigationStack {
                PantryEditorView(existing: nil)
                    .keyboardDoneAccessory()
            }
            .environmentObject(store)
        }
        .alert("Mark this cook complete?", isPresented: Binding(
            get: { pendingComplete != nil },
            set: { if !$0 { pendingComplete = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                pendingComplete = nil
            }
            .accessibilityIdentifier("kitchen.complete.cancel")
            Button("Complete", role: .destructive) {
                if let meal = pendingComplete {
                    store.completePlannedMeal(id: meal.id)
                    Haptics.success()
                }
                pendingComplete = nil
            }
            .accessibilityIdentifier("kitchen.complete.confirm")
        } message: {
            Text("Pantry amounts for used ingredients will decrease, and a cook history entry will be added.")
        }
    }

    private var pantrySummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionStamp(title: "Pantry ledger")
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(store.pantryItems.count)")
                        .font(.system(.largeTitle, design: .serif).weight(.bold))
                        .foregroundColor(Palette.ink)
                    Text(store.pantryItems.isEmpty ? "No ingredients yet" : "Ingredients on the shelf")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Palette.inkMuted)
                }
                Spacer()
                Image(systemName: "cabinet.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(Color("AppPrimary"))
            }

            HStack(spacing: 10) {
                NavigationLink {
                    PantryListView()
                } label: {
                    Label("Open pantry", systemImage: "list.bullet")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(HerbGradientButtonStyle())
                .accessibilityIdentifier("kitchen.openPantry")

                Button {
                    showAddPantry = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(HerbStampButtonStyle())
                .accessibilityIdentifier("kitchen.addPantry")
            }
        }
        .ledgerCard()
    }

    @ViewBuilder
    private var eatFirstCard: some View {
        let first = store.eatFirstItems
        if !first.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionStamp(title: "Eat first")
                ForEach(first.prefix(4)) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.system(.headline, design: .serif))
                                .foregroundColor(Palette.ink)
                            Text(eatFirstLine(item))
                                .font(.footnote.weight(.medium))
                                .foregroundColor(Palette.inkMuted)
                        }
                        Spacer()
                    }
                    .accessibilityIdentifier("kitchen.eatFirst.\(item.id)")
                }
            }
            .ledgerCard()
        }
    }

    private func eatFirstLine(_ item: PantryItem) -> String {
        guard let days = item.daysUntilExpiry() else { return item.unit }
        if days < 0 { return "Past its date" }
        if days == 0 { return "Use today" }
        if days == 1 { return "Use tomorrow" }
        return "Use in \(days) days"
    }

    @ViewBuilder
    private var tonightCard: some View {
        if let recipe = store.bestPantryRecipe() {
            let matched = store.coveredCount(for: recipe)
            VStack(alignment: .leading, spacing: 12) {
                SectionStamp(title: "Tonight from the shelf")
                HStack(spacing: 12) {
                    Image(systemName: recipe.symbolName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Color("AppPrimary"))
                        .frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recipe.name)
                            .font(.system(.headline, design: .serif))
                            .foregroundColor(Palette.ink)
                        Text("\(matched)/\(recipe.ingredients.count) on the shelf · \(recipe.cookMinutes) min")
                            .font(.footnote.weight(.medium))
                            .foregroundColor(Palette.inkMuted)
                    }
                }
                NavigationLink {
                    RecipeDetailView(recipe: recipe)
                } label: {
                    Label("Open this plate", systemImage: "book.fill")
                }
                .buttonStyle(HerbGradientButtonStyle())
                .accessibilityIdentifier("kitchen.tonight")
            }
            .ledgerCard()
        }
    }

    @ViewBuilder
    private var lowStockCard: some View {
        let low = store.lowStockItems
        if !low.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionStamp(title: "Running low")
                ForEach(low.prefix(4)) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.system(.headline, design: .serif))
                                .foregroundColor(Palette.ink)
                            Text("\(LedgerFormat.quantity(item.quantity)) \(item.unit) left")
                                .font(.footnote.weight(.medium))
                                .foregroundColor(Palette.inkMuted)
                        }
                        Spacer()
                        Button {
                            store.sendPantryToMarket(item)
                            Haptics.light()
                        } label: {
                            Text("Market")
                                .font(.caption.weight(.bold))
                                .foregroundColor(Color("AppPrimary"))
                                .frame(minWidth: 44, minHeight: 36)
                        }
                        .accessibilityIdentifier("kitchen.low.market.\(item.id)")
                    }
                }
            }
            .ledgerCard()
        }
    }

    private var weekStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionStamp(title: "This week")
            HStack(spacing: 6) {
                ForEach(store.weekSlots()) { slot in
                    let today = Calendar.current.isDateInToday(slot.date)
                    VStack(spacing: 6) {
                        Text(LedgerFormat.shortWeekday.string(from: slot.date))
                            .font(.caption.weight(.bold))
                            .foregroundColor(today ? Color("AppPrimary") : Palette.inkMuted)
                        Text(slot.meals.isEmpty ? "–" : "\(slot.meals.count)")
                            .font(.system(.headline, design: .serif).weight(.bold))
                            .foregroundColor(Palette.ink)
                    }
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(today ? Color("AppAccent").opacity(0.22) : Color.white.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            NavigationLink {
                WeekPlanView()
            } label: {
                Label("Open week calendar", systemImage: "calendar")
            }
            .buttonStyle(HerbGradientButtonStyle())
            .accessibilityIdentifier("kitchen.openWeek")
        }
        .ledgerCard()
    }

    private var plannedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionStamp(title: "Planned cooks")
            if store.openPlannedMeals.isEmpty {
                Text("Plan a recipe to pin a cook date here. Missing items move to Market.")
                    .font(.system(.body, design: .serif).weight(.medium))
                    .foregroundColor(Palette.inkMuted)
            } else {
                ForEach(store.openPlannedMeals) { meal in
                    plannedRow(meal)
                }
            }
        }
        .ledgerCard()
    }

    private func plannedRow(_ meal: PlannedMeal) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.recipeName)
                        .font(.system(.headline, design: .serif))
                        .foregroundColor(Palette.ink)
                    Text(LedgerFormat.mediumDate.string(from: meal.plannedDate))
                        .font(.footnote.weight(.medium))
                        .foregroundColor(Palette.inkMuted)
                }
                Spacer()
                if let recipe = store.recipe(id: meal.recipeID) {
                    NavigationLink {
                        RecipeDetailView(recipe: recipe)
                    } label: {
                        Image(systemName: "book.fill")
                            .frame(width: 44, height: 44)
                            .foregroundColor(Color("AppPrimary"))
                    }
                    .accessibilityIdentifier("kitchen.plan.open.\(meal.id)")
                }
            }
            Button {
                pendingComplete = meal
            } label: {
                Label("Complete cook", systemImage: "checkmark.seal.fill")
            }
            .buttonStyle(HerbGradientButtonStyle())
            .accessibilityIdentifier("kitchen.plan.complete.\(meal.id)")
        }
        .padding(.vertical, 4)
    }

    private var historyShortcut: some View {
        NavigationLink {
            CookHistoryView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color("AppPrimary"))
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cook history")
                        .font(.system(.headline, design: .serif))
                        .foregroundColor(Palette.ink)
                    Text(store.cookHistory.isEmpty ? "No meals stamped yet" : "\(store.cookHistory.count) cooked")
                        .font(.footnote.weight(.medium))
                        .foregroundColor(Palette.inkMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Palette.ink.opacity(0.35))
            }
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .ledgerCard()
        .accessibilityIdentifier("kitchen.openHistory")
    }
}
