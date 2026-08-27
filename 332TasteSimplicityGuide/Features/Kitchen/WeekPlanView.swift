import SwiftUI

struct WeekPlanView: View {
    @EnvironmentObject private var store: AppStore
    @State private var pendingComplete: PlannedMeal?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                WorkshopBanner(
                    imageName: "bannerRecipe",
                    title: "Week on the stove",
                    subtitle: "Seven days of planned cooks, from the start of this week."
                )
                ForEach(store.weekSlots()) { slot in
                    dayCard(slot)
                }
            }
            .padding(16)
            .padding(.bottom, 28)
        }
        .screenBackdrop()
        .navigationTitle("Week")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Mark this cook complete?", isPresented: Binding(
            get: { pendingComplete != nil },
            set: { if !$0 { pendingComplete = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingComplete = nil }
            Button("Complete", role: .destructive) {
                if let meal = pendingComplete {
                    store.completePlannedMeal(id: meal.id)
                    Haptics.success()
                }
                pendingComplete = nil
            }
        } message: {
            Text("Pantry amounts for used ingredients will decrease.")
        }
    }

    private func dayCard(_ slot: WeekDaySlot) -> some View {
        let today = Calendar.current.isDateInToday(slot.date)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(LedgerFormat.weekdayDay.string(from: slot.date))
                    .font(.system(.headline, design: .serif).weight(.bold))
                    .foregroundColor(Palette.ink)
                if today {
                    Text("Today")
                        .font(.caption.weight(.bold))
                        .foregroundColor(Color("AppPrimary"))
                }
            }
            if slot.meals.isEmpty {
                Text("No cook pinned")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Palette.inkMuted)
            } else {
                ForEach(slot.meals) { meal in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(meal.recipeName)
                                .font(.system(.body, design: .serif).weight(.semibold))
                                .foregroundColor(Palette.ink)
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
                        }
                        Button {
                            pendingComplete = meal
                        } label: {
                            Image(systemName: "checkmark.seal.fill")
                                .frame(width: 44, height: 44)
                                .foregroundColor(Color("AppPrimary"))
                        }
                        .accessibilityIdentifier("week.complete.\(meal.id)")
                    }
                }
            }
        }
        .ledgerCard()
        .accessibilityIdentifier("week.day.\(slot.id.timeIntervalSince1970)")
    }
}
