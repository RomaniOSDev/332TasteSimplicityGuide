import SwiftUI
import Charts

struct KitchenStatsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                WorkshopBanner(
                    imageName: "bannerTimer",
                    title: "Kitchen pulse",
                    subtitle: "Cooks, minutes, and what the shelf is actually covering."
                )

                summaryGrid
                weekCooksChart
                minutesChart
                topRecipesChart
                pantryMixChart
            }
            .padding(16)
            .padding(.bottom, 28)
        }
        .screenBackdrop()
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summaryGrid: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                statTile(value: "\(store.cooksThisWeek)", label: "Cooks this week", symbol: "fork.knife")
                statTile(value: "\(store.cookStreak)", label: "Day streak", symbol: "flame.fill")
            }
            HStack(spacing: 10) {
                statTile(value: "\(store.minutesThisWeek)", label: "Minutes cooked", symbol: "clock.fill")
                statTile(value: "\(store.pantryItems.count)", label: "On the shelf", symbol: "cabinet.fill")
            }
        }
    }

    private func statTile(value: String, label: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color("AppPrimary"))
            Text(value)
                .font(.system(.title, design: .serif).weight(.bold))
                .foregroundColor(Palette.ink)
            Text(label)
                .font(.system(.caption, design: .serif).weight(.semibold))
                .foregroundColor(Palette.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
        .ledgerCard()
    }

    private var weekCooksChart: some View {
        let days = store.cooksByDay(days: 7)
        return VStack(alignment: .leading, spacing: 12) {
            SectionStamp(title: "Cooks · last 7 days")
            if days.allSatisfy({ $0.count == 0 }) {
                Text("Complete a planned cook to stamp the first bar.")
                    .font(.system(.subheadline, design: .serif).weight(.medium))
                    .foregroundColor(Palette.inkMuted)
            }
            Chart(days) { day in
                BarMark(
                    x: .value("Day", day.id, unit: .day),
                    y: .value("Cooks", day.count)
                )
                .foregroundStyle(Color("AppAccent"))
            }
            .chartYScale(domain: 0...(max(3, (days.map(\.count).max() ?? 0) + 1)))
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(Palette.ink.opacity(0.12))
                    AxisValueLabel().foregroundStyle(Palette.ink)
                }
            }
            .chartXAxis {
                AxisMarks(values: days.map(\.id)) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(LedgerFormat.shortWeekday.string(from: date))
                                .foregroundColor(Palette.ink)
                        }
                    }
                }
            }
            .frame(height: 180)
            .accessibilityIdentifier("stats.chart.week")
        }
        .ledgerCard()
    }

    private var minutesChart: some View {
        let days = store.cooksByDay(days: 7)
        return VStack(alignment: .leading, spacing: 12) {
            SectionStamp(title: "Minutes at the stove")
            Chart(days) { day in
                AreaMark(
                    x: .value("Day", day.id, unit: .day),
                    y: .value("Minutes", day.minutes)
                )
                .foregroundStyle(Color("AppAccent").opacity(0.28))
                LineMark(
                    x: .value("Day", day.id, unit: .day),
                    y: .value("Minutes", day.minutes)
                )
                .foregroundStyle(Color("AppPrimary"))
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                PointMark(
                    x: .value("Day", day.id, unit: .day),
                    y: .value("Minutes", day.minutes)
                )
                .foregroundStyle(Color("AppPrimary"))
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(Palette.ink.opacity(0.12))
                    AxisValueLabel().foregroundStyle(Palette.ink)
                }
            }
            .chartXAxis {
                AxisMarks(values: days.map(\.id)) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(LedgerFormat.shortWeekday.string(from: date))
                                .foregroundColor(Palette.ink)
                        }
                    }
                }
            }
            .frame(height: 180)
            .accessibilityIdentifier("stats.chart.minutes")
        }
        .ledgerCard()
    }

    private var topRecipesChart: some View {
        let top = store.topCookedRecipes()
        return VStack(alignment: .leading, spacing: 12) {
            SectionStamp(title: "Most cooked plates")
            if top.isEmpty {
                Text("Favorite plates will stack here after the first completed cook.")
                    .font(.system(.subheadline, design: .serif).weight(.medium))
                    .foregroundColor(Palette.inkMuted)
            } else {
                Chart(top) { item in
                    BarMark(
                        x: .value("Times", item.count),
                        y: .value("Recipe", item.name)
                    )
                    .foregroundStyle(Color("AppPrimary"))
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(Palette.ink.opacity(0.12))
                        AxisValueLabel().foregroundStyle(Palette.ink)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel().foregroundStyle(Palette.ink)
                    }
                }
                .frame(height: CGFloat(max(140, top.count * 44)))
                .accessibilityIdentifier("stats.chart.top")
            }
        }
        .ledgerCard()
    }

    private var pantryMixChart: some View {
        let mix = store.pantryCategoryCounts()
        return VStack(alignment: .leading, spacing: 12) {
            SectionStamp(title: "Shelf by category")
            if mix.isEmpty {
                Text("Add pantry items to see how the shelf splits.")
                    .font(.system(.subheadline, design: .serif).weight(.medium))
                    .foregroundColor(Palette.inkMuted)
            } else {
                Chart(mix) { item in
                    BarMark(
                        x: .value("Items", item.count),
                        y: .value("Category", item.name)
                    )
                    .foregroundStyle(Color("AppAccent"))
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(Palette.ink.opacity(0.12))
                        AxisValueLabel().foregroundStyle(Palette.ink)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel().foregroundStyle(Palette.ink)
                    }
                }
                .frame(height: CGFloat(max(140, mix.count * 36)))
                .accessibilityIdentifier("stats.chart.pantry")
            }
            HStack {
                mixCaption(title: "Market open", value: "\(store.openGroceryCount)")
                Spacer()
                mixCaption(title: "Planned cooks", value: "\(store.openPlannedMeals.count)")
            }
        }
        .ledgerCard()
    }

    private func mixCaption(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(.title3, design: .serif).weight(.bold))
                .foregroundColor(Palette.ink)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(Palette.inkMuted)
        }
    }
}
