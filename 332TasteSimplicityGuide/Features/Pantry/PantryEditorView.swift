import SwiftUI

struct PantryEditorView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let existing: PantryItem?

    @State private var name: String = ""
    @State private var category: String = PantryCatalog.categories[0]
    @State private var quantityText: String = "1"
    @State private var unit: String = PantryCatalog.units[0]
    @State private var nameError: String = ""
    @State private var quantityError: String = ""
    @State private var confirmDelete = false
    @State private var tracksExpiry = false
    @State private var expiresAt = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(existing == nil ? "New pantry item" : "Edit pantry item")
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundColor(Palette.onDark)

                VStack(alignment: .leading, spacing: 12) {
                    LedgerTextField(
                        title: "Name",
                        identifier: "pantry.field.name",
                        text: $name
                    )
                    FieldErrorText(message: nameError, identifier: "pantry.error.name")

                    categoryPicker
                    unitPicker

                    LedgerTextField(
                        title: "Quantity",
                        identifier: "pantry.field.quantity",
                        text: $quantityText,
                        keyboard: .decimalPad
                    )
                    FieldErrorText(message: quantityError, identifier: "pantry.error.quantity")

                    Toggle(isOn: $tracksExpiry) {
                        Text("Use first date")
                            .font(.system(.subheadline, design: .serif).weight(.semibold))
                            .foregroundColor(Palette.ink)
                    }
                    .tint(Color("AppAccent"))
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("pantry.field.expiry.toggle")

                    if tracksExpiry {
                        DatePicker("Eat by", selection: $expiresAt, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .tint(Color("AppAccent"))
                            .foregroundColor(Palette.ink)
                            .frame(minHeight: 44)
                            .accessibilityIdentifier("pantry.field.expiry")
                    }
                }
                .ledgerCard()

                Button(existing == nil ? "Add item" : "Save changes") {
                    save()
                }
                .buttonStyle(HerbGradientButtonStyle())
                .accessibilityIdentifier("pantry.save")

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(HerbStampButtonStyle())
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("pantry.cancel")

                if existing != nil {
                    Button("Delete item") {
                        confirmDelete = true
                    }
                    .buttonStyle(HerbStampButtonStyle())
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("pantry.editor.delete")
                }
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .screenBackdrop()
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: fillExisting)
        .alert("Delete this item?", isPresented: $confirmDelete) {
            Button("Cancel", role: .cancel) {}
                .accessibilityIdentifier("pantry.editor.delete.cancel")
            Button("Delete", role: .destructive) {
                if let existing {
                    store.deletePantry(id: existing.id)
                }
                dismiss()
            }
            .accessibilityIdentifier("pantry.editor.delete.confirm")
        }
    }

    private var categoryPicker: some View {
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
            .accessibilityIdentifier("pantry.field.category")
        }
    }

    private var unitPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("UNIT")
                .font(.system(.caption, design: .serif).weight(.bold))
                .foregroundColor(Color("AppPrimary"))
            Picker("Unit", selection: $unit) {
                ForEach(PantryCatalog.units, id: \.self) { item in
                    Text(item).tag(item)
                }
            }
            .pickerStyle(.menu)
            .tint(Palette.ink)
            .frame(minHeight: 44)
            .accessibilityIdentifier("pantry.field.unit")
        }
    }

    private func fillExisting() {
        guard let existing else { return }
        name = existing.name
        category = existing.category
        quantityText = LedgerFormat.quantity(existing.quantity)
        unit = existing.unit
        if let expiry = existing.expiresAt {
            tracksExpiry = true
            expiresAt = expiry
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
        if !nameError.isEmpty {
            return
        }
        if var existing {
            existing.name = trimmed
            existing.category = category
            existing.quantity = quantity
            existing.unit = unit
            existing.expiresAt = tracksExpiry ? expiresAt : nil
            store.updatePantry(existing)
        } else {
            store.addPantry(
                name: trimmed,
                category: category,
                quantity: quantity,
                unit: unit,
                expiresAt: tracksExpiry ? expiresAt : nil
            )
        }
        dismiss()
    }
}
