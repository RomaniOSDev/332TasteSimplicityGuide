import SwiftUI

struct RecipeDetailView: View {
    @EnvironmentObject private var store: AppStore
    let recipe: Recipe

    @State private var planDate = Date()
    @State private var showPlanConfirm = false
    @State private var plannedNote: String?
    @State private var marketNote: String?
    @State private var servings: Int
    @State private var showCookMode = false
    @State private var noteText = ""

    init(recipe: Recipe) {
        self.recipe = recipe
        _servings = State(initialValue: max(1, recipe.servings))
    }

    private var scale: Double {
        Double(servings) / Double(max(1, recipe.servings))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                WorkshopBanner(
                    imageName: "bannerRecipe",
                    title: recipe.name,
                    subtitle: recipe.blurb
                )

                HStack(spacing: 10) {
                    Button {
                        store.toggleFavorite(recipeID: recipe.id)
                        Haptics.success()
                    } label: {
                        Label(
                            store.isFavorite(recipe.id) ? "Favorited" : "Favorite",
                            systemImage: store.isFavorite(recipe.id) ? "heart.fill" : "heart"
                        )
                    }
                    .buttonStyle(HerbGradientButtonStyle())
                    .accessibilityIdentifier("recipe.favorite")

                    Button {
                        showCookMode = true
                    } label: {
                        Label("Cook mode", systemImage: "text.alignleft")
                    }
                    .buttonStyle(HerbStampButtonStyle())
                    .accessibilityIdentifier("recipe.cookMode")
                }

                Button {
                    store.startTimerFromRecipe(recipe)
                    Haptics.light()
                } label: {
                    Label("Start timer", systemImage: "timer")
                }
                .buttonStyle(HerbStampButtonStyle())
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("recipe.startTimer")

                servingsCard
                ingredientsCard
                methodCard
                notesCard
                planCard
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.immediately)
        .keyboardDoneAccessory()
        .screenBackdrop()
        .navigationTitle("Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.markViewed(recipeID: recipe.id)
            noteText = store.note(for: recipe.id)
        }
        .fullScreenCover(isPresented: $showCookMode) {
            NavigationStack {
                CookModeView(recipe: recipe)
            }
        }
        .alert("Pin this cook?", isPresented: $showPlanConfirm) {
            Button("Cancel", role: .cancel) {}
                .accessibilityIdentifier("recipe.plan.cancel")
            Button("Plan cook") {
                store.planCook(recipe: recipe, date: planDate)
                Haptics.success()
                let missing = store.missingIngredients(for: recipe).count
                plannedNote = missing == 0
                    ? "Cook date saved. The pantry already covers this plate."
                    : "Cook date saved. \(missing) missing item\(missing == 1 ? "" : "s") moved to Market."
            }
            .accessibilityIdentifier("recipe.plan.confirm")
        } message: {
            Text("Missing ingredients will be added to the grocery list.")
        }
    }

    private var servingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionStamp(title: "Servings")
            HStack {
                Text("Scaled for \(servings)")
                    .font(.system(.headline, design: .serif))
                    .foregroundColor(Palette.ink)
                Spacer()
                Button {
                    servings = max(1, servings - 1)
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 44, height: 44)
                        .foregroundColor(Color("AppPrimary"))
                }
                .accessibilityIdentifier("recipe.servings.minus")
                Text("\(servings)")
                    .font(.system(.title3, design: .serif).monospacedDigit().weight(.bold))
                    .foregroundColor(Palette.ink)
                    .frame(minWidth: 28)
                Button {
                    servings = min(12, servings + 1)
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 44, height: 44)
                        .foregroundColor(Color("AppPrimary"))
                }
                .accessibilityIdentifier("recipe.servings.plus")
            }
            Text("Original recipe is \(recipe.servings) serving\(recipe.servings == 1 ? "" : "s").")
                .font(.footnote.weight(.medium))
                .foregroundColor(Palette.inkMuted)
            if let shelf = store.shelfServings(for: recipe) {
                Button {
                    servings = shelf
                    Haptics.light()
                } label: {
                    Label("Scale to shelf (\(shelf))", systemImage: "cabinet.fill")
                }
                .buttonStyle(HerbStampButtonStyle())
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("recipe.scaleShelf")
            }
        }
        .ledgerCard()
    }

    private var ingredientsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionStamp(title: "Ingredients")
            ForEach(recipe.ingredients) { item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: store.hasInPantry(item.name) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(store.hasInPantry(item.name) ? Color("AppPrimary") : Palette.ink.opacity(0.35))
                        Text("\(LedgerFormat.quantity(item.quantity * scale)) \(item.unit) \(item.name)")
                            .font(.system(.body, design: .serif).weight(.medium))
                            .foregroundColor(Palette.ink)
                        Spacer()
                        Text(store.hasInPantry(item.name) ? "Have" : "Missing")
                            .font(.caption.weight(.bold))
                            .foregroundColor(store.hasInPantry(item.name) ? Color("AppPrimary") : Palette.ink)
                    }
                    if !store.hasInPantry(item.name), let swap = store.substitutionOnShelf(for: item.name) {
                        Text("Use \(swap) from the shelf")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(Color("AppPrimary"))
                            .padding(.leading, 28)
                            .accessibilityIdentifier("recipe.swap.\(item.id)")
                    }
                }
                .frame(minHeight: 36)
                .accessibilityIdentifier("recipe.ingredient.\(item.id)")
            }
            if !store.missingIngredients(for: recipe).isEmpty {
                Button {
                    let count = store.missingIngredients(for: recipe).count
                    store.addMissingIngredientsToMarket(for: recipe)
                    Haptics.success()
                    marketNote = "\(count) item\(count == 1 ? "" : "s") moved to Market."
                } label: {
                    Label("Send missing to Market", systemImage: "cart.badge.plus")
                }
                .buttonStyle(HerbStampButtonStyle())
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("recipe.sendMissing")
                if let marketNote {
                    Text(marketNote)
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(Color("AppPrimary"))
                }
            }
        }
        .ledgerCard()
    }

    private var methodCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionStamp(title: "Method")
            ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                Text("\(index + 1). \(step)")
                    .font(.system(.body, design: .serif).weight(.medium))
                    .foregroundColor(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .ledgerCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionStamp(title: "Your notes")
            LedgerTextField(title: "Tweak", identifier: "recipe.note", text: $noteText)
            Button("Save note") {
                store.setNote(noteText, for: recipe.id)
                Keyboard.dismiss()
                Haptics.light()
            }
            .buttonStyle(HerbStampButtonStyle())
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("recipe.note.save")
        }
        .ledgerCard()
    }

    private var planCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionStamp(title: "Plan cook")
            DatePicker("Cook date", selection: $planDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .tint(Color("AppAccent"))
                .foregroundColor(Palette.ink)
                .frame(minHeight: 44)
                .accessibilityIdentifier("recipe.plan.date")
            Button {
                showPlanConfirm = true
            } label: {
                Label("Plan this meal", systemImage: "calendar.badge.plus")
            }
            .buttonStyle(HerbGradientButtonStyle())
            .accessibilityIdentifier("recipe.plan")
            if let plannedNote {
                Text(plannedNote)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(Color("AppPrimary"))
            }
        }
        .ledgerCard()
    }
}
