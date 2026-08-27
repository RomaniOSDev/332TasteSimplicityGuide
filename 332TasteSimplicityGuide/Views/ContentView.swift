import SwiftUI

enum DockTab: String, CaseIterable {
    case kitchen
    case recipes
    case market
    case heat
    case stats

    var title: String {
        switch self {
        case .kitchen: return "Kitchen"
        case .recipes: return "Recipes"
        case .market: return "Market"
        case .heat: return "Heat"
        case .stats: return "Stats"
        }
    }

    var symbol: String {
        switch self {
        case .kitchen: return "leaf.fill"
        case .recipes: return "book.fill"
        case .market: return "cart.fill"
        case .heat: return "flame.fill"
        case .stats: return "chart.bar.fill"
        }
    }

    var accessibilityID: String {
        "dock.\(rawValue)"
    }
}

struct ContentView: View {
    @StateObject var store = AppStore()
    @State private var selectedTab: DockTab = .kitchen
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            tabRoot
            dockBar
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .keyboardDoneAccessory()
            }
            .environmentObject(store)
        }
        .environmentObject(store)
        .onAppear {
            ThemeChrome.apply()
            store.settleExpiredTimers(at: Date())
        }
    }

    @ViewBuilder
    private var tabRoot: some View {
        switch selectedTab {
        case .kitchen:
            NavigationStack {
                KitchenHomeView()
                    .toolbar { settingsToolbar }
            }
        case .recipes:
            NavigationStack {
                RecipeListView()
                    .toolbar { settingsToolbar }
            }
        case .market:
            NavigationStack {
                GroceryListView()
                    .toolbar { settingsToolbar }
            }
        case .heat:
            NavigationStack {
                TimerListView()
                    .toolbar { settingsToolbar }
            }
        case .stats:
            NavigationStack {
                KitchenStatsView()
                    .toolbar { settingsToolbar }
            }
        }
    }

    @ToolbarContentBuilder
    private var settingsToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(Palette.onDark)
                    .frame(width: 44, height: 44)
            }
            .accessibilityIdentifier("openSettings")
        }
    }

    private var dockBar: some View {
        HStack(spacing: 2) {
            ForEach(DockTab.allCases, id: \.self) { tab in
                Button {
                    Haptics.light()
                    selectedTab = tab
                } label: {
                    let selected = selectedTab == tab
                    VStack(spacing: 4) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 34)
                            .background(
                                Capsule()
                                    .fill(selected ? Color("AppAccent") : Color.clear)
                            )
                            .shadow(color: selected ? Color("AppAccent").opacity(0.55) : .clear, radius: 6, y: 1)
                        Text(tab.title)
                            .font(.system(size: 11, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .opacity(selected ? 1 : 0.82)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .opacity(selected ? 1 : 0.92)
                    .frame(maxWidth: .infinity, minHeight: 58)
                }
                .accessibilityIdentifier(tab.accessibilityID)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background {
            Color("AppBackground")
                .overlay(Color.black.opacity(0.22))
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.white.opacity(0.22))
                        .frame(height: 1)
                }
                .shadow(color: Color.black.opacity(0.45), radius: 12, x: 0, y: -4)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}
