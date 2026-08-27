import SwiftUI

struct TimerEditorView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let existing: DishTimer?

    @State private var dishName = ""
    @State private var minutesText = "15"
    @State private var notes = ""
    @State private var nameError = ""
    @State private var timeError = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(existing == nil ? "New dish timer" : "Edit dish timer")
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundColor(Palette.onDark)

                VStack(alignment: .leading, spacing: 12) {
                    LedgerTextField(title: "Dish name", identifier: "timer.field.name", text: $dishName)
                    FieldErrorText(message: nameError, identifier: "timer.error.name")
                    LedgerTextField(
                        title: "Minutes",
                        identifier: "timer.field.minutes",
                        text: $minutesText,
                        keyboard: .numberPad
                    )
                    FieldErrorText(message: timeError, identifier: "timer.error.minutes")
                    LedgerTextField(title: "Notes", identifier: "timer.field.notes", text: $notes)
                }
                .ledgerCard()

                Button(existing == nil ? "Create timer" : "Save changes") {
                    save()
                }
                .buttonStyle(HerbGradientButtonStyle())
                .accessibilityIdentifier("timer.save")

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(HerbStampButtonStyle())
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("timer.cancel")
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .screenBackdrop()
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard let existing else { return }
            dishName = existing.dishName
            minutesText = String(max(1, existing.durationSec / 60))
            notes = existing.notes
        }
    }

    private func save() {
        nameError = ""
        timeError = ""
        let trimmed = dishName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            nameError = "Name each timer so overlapping dishes stay clear."
        }
        guard let minutes = Int(minutesText), minutes > 0 else {
            timeError = "Duration must be at least 1 minute."
            return
        }
        if !nameError.isEmpty { return }
        let duration = minutes * 60
        if var existing {
            guard existing.allowsEdit(at: Date()) else {
                timeError = "This clock is too close to finishing to edit."
                return
            }
            existing.dishName = trimmed
            existing.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.durationSec = duration
            if existing.startedAt == nil {
                existing.remainingSec = duration
            }
            store.updateTimer(existing)
        } else {
            store.addTimer(dishName: trimmed, durationSec: duration, notes: notes.trimmingCharacters(in: .whitespacesAndNewlines), startNow: true)
            Haptics.success()
        }
        dismiss()
    }
}
