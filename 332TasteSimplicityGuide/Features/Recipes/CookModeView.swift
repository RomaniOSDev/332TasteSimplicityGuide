import SwiftUI
import UIKit

struct CookModeView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    @State private var stepIndex = 0
    @State private var doneSteps: Set<Int> = []

    var body: some View {
        VStack(spacing: 0) {
            progress
            Spacer(minLength: 12)
            stepBody
            Spacer(minLength: 12)
            controls
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .screenBackdrop()
        .navigationTitle("Cook mode")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
                    .foregroundColor(Palette.onDark)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityIdentifier("cook.done")
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private var progress: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(recipe.name)
                .font(.system(.title2, design: .serif).weight(.bold))
                .foregroundColor(Palette.onDark)
            Text("Step \(stepIndex + 1) of \(max(1, recipe.steps.count))")
                .font(.headline)
                .foregroundColor(Palette.onDark)
            GeometryReader { geo in
                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(Color("AppAccent"))
                            .frame(width: geo.size.width * progressValue)
                    }
            }
            .frame(height: 8)
        }
    }

    private var progressValue: CGFloat {
        guard !recipe.steps.isEmpty else { return 1 }
        return CGFloat(stepIndex + 1) / CGFloat(recipe.steps.count)
    }

    private var stepBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(currentStep)
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .foregroundColor(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                if doneSteps.contains(stepIndex) {
                    doneSteps.remove(stepIndex)
                } else {
                    doneSteps.insert(stepIndex)
                    Haptics.success()
                }
            } label: {
                Label(
                    doneSteps.contains(stepIndex) ? "Step done" : "Mark step done",
                    systemImage: doneSteps.contains(stepIndex) ? "checkmark.circle.fill" : "circle"
                )
            }
            .buttonStyle(HerbStampButtonStyle())
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("cook.mark")
        }
        .ledgerCard()
    }

    private var currentStep: String {
        guard recipe.steps.indices.contains(stepIndex) else {
            return "This plate is ready."
        }
        return recipe.steps[stepIndex]
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Button {
                stepIndex = max(0, stepIndex - 1)
            } label: {
                Label("Back", systemImage: "chevron.left")
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(HerbStampButtonStyle())
            .disabled(stepIndex == 0)
            .opacity(stepIndex == 0 ? 0.45 : 1)
            .accessibilityIdentifier("cook.back")

            Button {
                if stepIndex < recipe.steps.count - 1 {
                    stepIndex += 1
                } else {
                    dismiss()
                }
            } label: {
                Label(
                    stepIndex < recipe.steps.count - 1 ? "Next" : "Finish",
                    systemImage: stepIndex < recipe.steps.count - 1 ? "chevron.right" : "checkmark"
                )
                .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(HerbGradientButtonStyle())
            .accessibilityIdentifier("cook.next")
        }
    }
}
