import SwiftUI

struct GroceryEditorView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let existing: GroceryItem?

    @State private var name = ""
    @State private var category = PantryCatalog.categories[0]
    @State private var quantityText = "1"
    @State private var nameError = ""
    @State private var quantityError = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(existing == nil ? "New market item" : "Edit market item")
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundColor(Palette.onDark)

                VStack(alignment: .leading, spacing: 12) {
                    LedgerTextField(title: "Name", identifier: "grocery.field.name", text: $name)
                    FieldErrorText(message: nameError, identifier: "grocery.error.name")

                    VStack(alignment: .leading, spacing: 6) {
                        Text("CATEGORY")
                            .font(.system(.caption, design: .serif).weight(.bold))
                            .foregroundColor(Color("AppPrimary"))
                        Picker("Category", selection: $category) {
                            ForEach(PantryCatalog.categories, id: \.self) { item in
                                Text(item).tag(item)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Palette.ink)
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("grocery.field.category")
                    }

                    LedgerTextField(
                        title: "Quantity",
                        identifier: "grocery.field.quantity",
                        text: $quantityText,
                        keyboard: .decimalPad
                    )
                    FieldErrorText(message: quantityError, identifier: "grocery.error.quantity")
                }
                .ledgerCard()

                Button(existing == nil ? "Add item" : "Save changes") {
                    save()
                }
                .buttonStyle(HerbGradientButtonStyle())
                .accessibilityIdentifier("grocery.save")

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(HerbStampButtonStyle())
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("grocery.cancel")
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .screenBackdrop()
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard let existing else { return }
            name = existing.name
            category = existing.category
            quantityText = LedgerFormat.quantity(existing.quantity)
        }
    }

    private func save() {
        nameError = ""
        quantityError = ""
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            nameError = "Name is required"
        }
        let normalized = quantityText.replacingOccurrences(of: ",", with: ".")
        guard let quantity = Double(normalized), quantity > 0 else {
            quantityError = "Quantity must be greater than 0"
            return
        }
        if !nameError.isEmpty { return }
        if var existing {
            existing.name = trimmed
            existing.category = category
            existing.quantity = quantity
            store.updateGrocery(existing)
        } else {
            store.addGrocery(name: trimmed, category: category, quantity: quantity)
        }
        dismiss()
    }
}
