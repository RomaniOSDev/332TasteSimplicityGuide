import SwiftUI

struct RecipeListView: View {
    @EnvironmentObject private var store: AppStore
    @State private var query = ""
    @State private var favoritesOnly = false

    var body: some View {
        List {
            Section {
                WorkshopBanner(
                    imageName: "bannerRecipe",
                    title: "Recipe ledger",
                    subtitle: "Green checks mean the shelf already covers it."
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                filterCard
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            if visibleRecipes.isEmpty {
                LedgerEmptyState(
                    symbol: "magnifyingglass",
                    message: emptyMessage
                )
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(visibleRecipes) { recipe in
                    NavigationLink {
                        RecipeDetailView(recipe: recipe)
                    } label: {
                        recipeRow(recipe)
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .accessibilityIdentifier("recipes.row.\(recipe.id)")
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .screenBackdrop()
        .navigationTitle("Recipes")
        .navigationBarTitleDisplayMode(.inline)
        .keyboardDoneAccessory()
    }

    private var filterCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            LedgerTextField(title: "Search", identifier: "recipes.search", text: $query)
            Picker("Sort", selection: Binding(
                get: { store.recipeSortOrder },
                set: { store.setSortOrder($0) }
            )) {
                Text("Match").tag("match")
                Text("Time").tag("time")
                Text("Name").tag("name")
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("recipes.sort")

            Toggle(isOn: $favoritesOnly) {
                Text("Favorites only")
                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                    .foregroundColor(Palette.ink)
            }
            .tint(Color("AppAccent"))
            .frame(minHeight: 44)
            .accessibilityIdentifier("recipes.favoritesOnly")
        }
        .ledgerCard()
    }

    private var visibleRecipes: [Recipe] {
        store.sortedRecipes().filter { recipe in
            if favoritesOnly && !store.isFavorite(recipe.id) {
                return false
            }
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return true }
            return recipe.name.localizedCaseInsensitiveContains(trimmed)
                || recipe.blurb.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var emptyMessage: String {
        if favoritesOnly {
            return "No favorites match this search yet. Heart a plate first."
        }
        if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "No recipes match that search."
        }
        return "Find your next meal here!"
    }

    private func recipeRow(_ recipe: Recipe) -> some View {
        let matched = store.matchCount(for: recipe)
        let total = recipe.ingredients.count
        return HStack(spacing: 12) {
            Image(systemName: recipe.symbolName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Color("AppPrimary"))
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.system(.headline, design: .serif))
                    .foregroundColor(Palette.ink)
                Text("\(recipe.cookMinutes) min · \(matched)/\(total) on the shelf")
                    .font(.footnote.weight(.medium))
                    .foregroundColor(Palette.inkMuted)
            }
            Spacer()
            if store.isFavorite(recipe.id) {
                Image(systemName: "heart.fill")
                    .foregroundColor(Color("AppPrimary"))
            }
        }
        .ledgerCard()
    }
}
