import SwiftUI

struct TimerListView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showAdd = false
    @State private var editingTimer: DishTimer?
    @State private var pendingDelete: DishTimer?

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 1)) { context in
            let now = context.date
            Group {
                if store.timers.isEmpty {
                    ScrollView {
                        VStack(spacing: 16) {
                            WorkshopBanner(
                                imageName: "bannerTimer",
                                title: "Heat clocks",
                                subtitle: "Name each dish so overlapping pots stay clear."
                            )
                        LedgerEmptyState(
                            symbol: "hourglass.circle",
                            message: "Create your first dish timer to start efficient meal preparation!"
                        )
                        presetRow
                        Button {
                            showAdd = true
                        } label: {
                            Label("Add timer", systemImage: "plus")
                        }
                        .buttonStyle(HerbGradientButtonStyle())
                        .accessibilityIdentifier("timer.add.empty")
                        }
                        .padding(16)
                    }
                    .screenBackdrop()
                } else {
                    List {
                        presetRow
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        ForEach(store.timers) { timer in
                            timerRow(timer, now: now)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        pendingDelete = timer
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .accessibilityIdentifier("timer.swipeDelete.\(timer.id)")
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .screenBackdrop()
                }
            }
            .onChange(of: now) { _ in
                store.settleExpiredTimers(at: now)
            }
        }
        .navigationTitle("Heat")
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
                .accessibilityIdentifier("timer.add")
            }
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                TimerEditorView(existing: nil)
                    .keyboardDoneAccessory()
            }
            .environmentObject(store)
        }
        .sheet(item: $editingTimer) { timer in
            NavigationStack {
                TimerEditorView(existing: timer)
                    .keyboardDoneAccessory()
            }
            .environmentObject(store)
        }
        .alert("Remove this timer?", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingDelete = nil }
                .accessibilityIdentifier("timer.delete.cancel")
            Button("Delete", role: .destructive) {
                if let item = pendingDelete {
                    store.deleteTimer(id: item.id)
                }
                pendingDelete = nil
            }
            .accessibilityIdentifier("timer.delete.confirm")
        }
        .alert(
            "Timer complete",
            isPresented: Binding(
                get: { store.recentlyCompletedTimerName != nil },
                set: { if !$0 { store.clearCompletedBanner() } }
            )
        ) {
            Button("OK", role: .cancel) {
                store.clearCompletedBanner()
            }
            .accessibilityIdentifier("timer.complete.ok")
        } message: {
            Text(store.recentlyCompletedTimerName.map { "\($0) is ready." } ?? "A dish timer finished.")
        }
    }

    private var presetRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionStamp(title: "Presets")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TimerPreset.all) { preset in
                        Button {
                            store.startPresetTimer(preset)
                            Haptics.light()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: preset.symbol)
                                    .font(.system(size: 16, weight: .bold))
                                Text(preset.name)
                                    .font(.caption.weight(.bold))
                                Text("\(preset.minutes) min")
                                    .font(.caption2.weight(.semibold))
                            }
                            .foregroundColor(Palette.ink)
                            .frame(width: 76, height: 72)
                            .background(Palette.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color("AppPrimary").opacity(0.45), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .accessibilityIdentifier("timer.preset.\(preset.id)")
                    }
                }
            }
        }
        .ledgerCard()
    }

    private func timerRow(_ timer: DishTimer, now: Date) -> some View {
        let remaining = timer.remaining(at: now)
        let done = timer.isCompleted(at: now)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(timer.dishName)
                        .font(.system(.headline, design: .serif))
                        .foregroundColor(Palette.ink)
                    Text(done ? "Complete" : DishTimer.clock(remaining))
                        .font(.system(.title2, design: .serif).monospacedDigit().weight(.bold))
                        .foregroundColor(Color("AppPrimary"))
                }
                Spacer()
                if timer.allowsEdit(at: now) {
                    Button {
                        editingTimer = timer
                    } label: {
                        Image(systemName: "pencil")
                            .frame(width: 44, height: 44)
                            .foregroundColor(Color("AppPrimary"))
                    }
                    .accessibilityIdentifier("timer.edit.\(timer.id)")
                }
                Button {
                    pendingDelete = timer
                } label: {
                    Image(systemName: "trash")
                        .frame(width: 44, height: 44)
                        .foregroundColor(Palette.ink)
                }
                .accessibilityIdentifier("timer.delete.\(timer.id)")
            }
            if !timer.notes.isEmpty {
                Text(timer.notes)
                    .font(.footnote.weight(.medium))
                    .foregroundColor(Palette.inkMuted)
            }
            HStack {
                if done {
                    Text("Done")
                        .font(.caption.weight(.bold))
                        .foregroundColor(Color("AppPrimary"))
                } else if timer.isRunning {
                    Button("Pause") {
                        store.pauseTimer(id: timer.id)
                    }
                    .buttonStyle(HerbStampButtonStyle())
                    .accessibilityIdentifier("timer.pause.\(timer.id)")
                } else {
                    Button("Start") {
                        store.startTimer(id: timer.id)
                    }
                    .buttonStyle(HerbGradientButtonStyle())
                    .accessibilityIdentifier("timer.start.\(timer.id)")
                }
            }
        }
        .ledgerCard()
        .accessibilityIdentifier("timer.row.\(timer.id)")
    }
}
