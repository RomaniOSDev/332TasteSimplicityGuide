import Foundation
import Combine

final class AppStore: ObservableObject {
    enum Keys {
        static let pantryItems = "pantryItems"
        static let favoriteRecipeIDs = "favoriteRecipeIDs"
        static let lastViewedRecipeID = "lastViewedRecipeID"
        static let recipeSortOrder = "recipeSortOrder"
        static let groceryItems = "groceryItems"
        static let lastSyncDate = "lastSyncDate"
        static let timers = "timers"
        static let activeNotifications = "activeNotifications"
        static let plannedMeals = "plannedMeals"
        static let cookHistory = "cookHistory"
        static let lastActivityDate = "lastActivityDate"
        static let recipeNotes = "recipeNotes"
        static let lastMarketTrip = "lastMarketTrip"
    }

    @Published var pantryItems: [PantryItem] = []
    @Published var favoriteRecipeIDs: [String] = []
    @Published var lastViewedRecipeID: String?
    @Published var recipeSortOrder: String = "match"
    @Published var groceryItems: [GroceryItem] = []
    @Published var lastSyncDate: Date?
    @Published var timers: [DishTimer] = []
    @Published var activeNotifications: Bool = true
    @Published var plannedMeals: [PlannedMeal] = []
    @Published var cookHistory: [CookRecord] = []
    @Published var lastActivityDate: Date?
    @Published var recentlyCompletedTimerName: String?
    @Published var recipeNotes: [String: String] = [:]
    @Published var lastMarketTrip: [GroceryItem] = []

    private var resetObserver: NSObjectProtocol?
    private let defaults = UserDefaults.standard
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init() {
        load()
        resetObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("dataReset"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.load()
        }
    }

    deinit {
        if let resetObserver {
            NotificationCenter.default.removeObserver(resetObserver)
        }
    }

    var recipes: [Recipe] {
        Recipe.catalog
    }

    var openPlannedMeals: [PlannedMeal] {
        plannedMeals
            .filter { !$0.isCompleted }
            .sorted { $0.plannedDate < $1.plannedDate }
    }

    var sortedGroceryItems: [GroceryItem] {
        groceryItems.sorted { left, right in
            if left.acquired != right.acquired {
                return !left.acquired && right.acquired
            }
            return left.name.localizedCaseInsensitiveCompare(right.name) == .orderedAscending
        }
    }

    var openGroceryCount: Int {
        groceryItems.filter { !$0.acquired }.count
    }

    var lowStockItems: [PantryItem] {
        pantryItems
            .filter { $0.quantity > 0 && $0.quantity <= 1 }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var cookStreak: Int {
        let calendar = Calendar.current
        let cookedDays = Set(cookHistory.map { calendar.startOfDay(for: $0.cookedAt) })
        guard !cookedDays.isEmpty else { return 0 }
        var cursor = calendar.startOfDay(for: Date())
        if !cookedDays.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
            if !cookedDays.contains(cursor) { return 0 }
        }
        var streak = 0
        while cookedDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    var cooksThisWeek: Int {
        cookHistory.filter { $0.cookedAt >= weekStart }.count
    }

    var minutesThisWeek: Int {
        cookHistory.filter { $0.cookedAt >= weekStart }.reduce(0) { $0 + $1.cookMinutes }
    }

    var eatFirstItems: [PantryItem] {
        pantryItems
            .filter(\.isEatFirst)
            .sorted {
                ($0.expiresAt ?? .distantFuture) < ($1.expiresAt ?? .distantFuture)
            }
    }

    func weekSlots(from now: Date = Date()) -> [WeekDaySlot] {
        let calendar = Calendar.current
        let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start
            ?? calendar.startOfDay(for: now)
        return (0..<7).compactMap { offset -> WeekDaySlot? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            let meals = plannedMeals
                .filter { !$0.isCompleted && calendar.isDate($0.plannedDate, inSameDayAs: day) }
                .sorted { $0.recipeName.localizedCaseInsensitiveCompare($1.recipeName) == .orderedAscending }
            return WeekDaySlot(id: day, date: day, meals: meals)
        }
    }

    func substitutionOnShelf(for ingredientName: String) -> String? {
        guard !hasInPantry(ingredientName) else { return nil }
        for candidate in IngredientSwap.candidates(for: ingredientName) {
            if hasInPantry(candidate) {
                return pantryItems.first(where: {
                    $0.quantity > 0 && AppStore.namesMatch($0.name, candidate)
                })?.name ?? candidate
            }
        }
        return nil
    }

    func coveredCount(for recipe: Recipe) -> Int {
        recipe.ingredients.filter { ingredient in
            hasInPantry(ingredient.name) || substitutionOnShelf(for: ingredient.name) != nil
        }.count
    }

    func shelfServings(for recipe: Recipe) -> Int? {
        var ratios: [Double] = []
        for ingredient in recipe.ingredients {
            let pantry = pantryItems.first {
                $0.quantity > 0 && AppStore.namesMatch($0.name, ingredient.name)
            }
            guard let pantry, pantry.unit == ingredient.unit, ingredient.quantity > 0 else { continue }
            ratios.append(pantry.quantity / ingredient.quantity)
        }
        guard let minRatio = ratios.min(), minRatio > 0 else { return nil }
        let scaled = Int((Double(max(1, recipe.servings)) * minRatio).rounded(.down))
        return min(12, max(1, scaled))
    }

    func note(for recipeID: String) -> String {
        recipeNotes[recipeID] ?? ""
    }

    func setNote(_ note: String, for recipeID: String) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            recipeNotes.removeValue(forKey: recipeID)
        } else {
            recipeNotes[recipeID] = trimmed
        }
        persist()
    }

    func repeatLastMarketTrip() {
        guard !lastMarketTrip.isEmpty else { return }
        for item in lastMarketTrip {
            enqueueGrocery(name: item.name, category: item.category, quantity: item.quantity)
        }
        persist()
    }

    func startPresetTimer(_ preset: TimerPreset) {
        addTimer(
            dishName: preset.name,
            durationSec: preset.durationSec,
            notes: "Preset · \(preset.minutes) min",
            startNow: true
        )
    }

    func bestPantryRecipe() -> Recipe? {
        recipes
            .map { recipe in
                (recipe: recipe, match: coveredCount(for: recipe), total: recipe.ingredients.count)
            }
            .filter { $0.total > 0 }
            .sorted { left, right in
                let leftRatio = Double(left.match) / Double(left.total)
                let rightRatio = Double(right.match) / Double(right.total)
                if leftRatio != rightRatio { return leftRatio > rightRatio }
                if left.match != right.match { return left.match > right.match }
                return left.recipe.cookMinutes < right.recipe.cookMinutes
            }
            .first?
            .recipe
    }

    func cooksByDay(days: Int, now: Date = Date()) -> [CookDayBucket] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: now)
        return (0..<days).reversed().compactMap { offset -> CookDayBucket? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: start) else { return nil }
            let records = cookHistory.filter { calendar.isDate($0.cookedAt, inSameDayAs: day) }
            return CookDayBucket(
                id: day,
                label: LedgerFormat.shortWeekday.string(from: day),
                count: records.count,
                minutes: records.reduce(0) { $0 + $1.cookMinutes }
            )
        }
    }

    func topCookedRecipes(limit: Int = 5) -> [RecipeCookStat] {
        let grouped = Dictionary(grouping: cookHistory, by: \.recipeName)
        return grouped
            .map { name, records in
                RecipeCookStat(
                    id: name,
                    name: name,
                    count: records.count,
                    minutes: records.reduce(0) { $0 + $1.cookMinutes }
                )
            }
            .sorted {
                if $0.count != $1.count { return $0.count > $1.count }
                return $0.minutes > $1.minutes
            }
            .prefix(limit)
            .map { $0 }
    }

    func pantryCategoryCounts() -> [CategoryCount] {
        Dictionary(grouping: pantryItems.filter { $0.quantity > 0 }, by: \.category)
            .map { CategoryCount(id: $0.key, name: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    func addMissingIngredientsToMarket(for recipe: Recipe) {
        for ingredient in missingIngredients(for: recipe) {
            enqueueGrocery(name: ingredient.name, category: ingredient.category, quantity: ingredient.quantity)
        }
        persist()
    }

    func sendPantryToMarket(_ item: PantryItem) {
        enqueueGrocery(name: item.name, category: item.category, quantity: max(1, item.quantity))
        persist()
    }

    func restockGroceryToPantry(id: String) {
        guard let item = groceryItems.first(where: { $0.id == id }) else { return }
        mergeIntoPantry(name: item.name, category: item.category, quantity: item.quantity, unit: "pcs")
        groceryItems.removeAll { $0.id == id }
        persist()
    }

    func restockAllAcquired() {
        let acquired = groceryItems.filter(\.acquired)
        guard !acquired.isEmpty else { return }
        for item in acquired {
            mergeIntoPantry(name: item.name, category: item.category, quantity: item.quantity, unit: "pcs")
        }
        groceryItems.removeAll(where: \.acquired)
        persist()
    }

    func recipe(id: String) -> Recipe? {
        recipes.first { $0.id == id }
    }

    func isFavorite(_ recipeID: String) -> Bool {
        favoriteRecipeIDs.contains(recipeID)
    }

    static func namesMatch(_ first: String, _ second: String) -> Bool {
        let a = first.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let b = second.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if a.isEmpty || b.isEmpty {
            return false
        }
        return a.contains(b) || b.contains(a)
    }

    func hasInPantry(_ ingredientName: String) -> Bool {
        pantryItems.contains { item in
            item.quantity > 0 && AppStore.namesMatch(item.name, ingredientName)
        }
    }

    func matchCount(for recipe: Recipe) -> Int {
        recipe.ingredients.filter { hasInPantry($0.name) }.count
    }

    func missingIngredients(for recipe: Recipe) -> [RecipeIngredient] {
        recipe.ingredients.filter { !hasInPantry($0.name) }
    }

    func sortedRecipes() -> [Recipe] {
        let all = recipes
        switch recipeSortOrder {
        case "time":
            return all.sorted { $0.cookMinutes < $1.cookMinutes }
        case "name":
            return all.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        default:
            return all.sorted { left, right in
                let leftMatch = matchCount(for: left)
                let rightMatch = matchCount(for: right)
                if leftMatch != rightMatch {
                    return leftMatch > rightMatch
                }
                return left.name.localizedCaseInsensitiveCompare(right.name) == .orderedAscending
            }
        }
    }

    func setSortOrder(_ order: String) {
        recipeSortOrder = order
        persist()
    }

    func markViewed(recipeID: String) {
        lastViewedRecipeID = recipeID
        persist()
    }

    func toggleFavorite(recipeID: String) {
        if let index = favoriteRecipeIDs.firstIndex(of: recipeID) {
            favoriteRecipeIDs.remove(at: index)
        } else {
            favoriteRecipeIDs.append(recipeID)
        }
        persist()
    }

    func addPantry(name: String, category: String, quantity: Double, unit: String, expiresAt: Date? = nil) {
        let item = PantryItem(
            id: UUID().uuidString,
            name: name,
            category: category,
            quantity: quantity,
            unit: unit,
            expiresAt: expiresAt
        )
        pantryItems.append(item)
        persist()
    }

    func updatePantry(_ item: PantryItem) {
        guard let index = pantryItems.firstIndex(where: { $0.id == item.id }) else { return }
        pantryItems[index] = item
        persist()
    }

    func deletePantry(id: String) {
        pantryItems.removeAll { $0.id == id }
        persist()
    }

    func addGrocery(name: String, category: String, quantity: Double) {
        let item = GroceryItem(
            id: UUID().uuidString,
            name: name,
            category: category,
            quantity: quantity,
            acquired: false
        )
        groceryItems.append(item)
        persist()
    }

    func updateGrocery(_ item: GroceryItem) {
        guard let index = groceryItems.firstIndex(where: { $0.id == item.id }) else { return }
        groceryItems[index] = item
        persist()
    }

    func deleteGrocery(id: String) {
        groceryItems.removeAll { $0.id == id }
        persist()
    }

    func toggleAcquired(id: String) {
        guard let index = groceryItems.firstIndex(where: { $0.id == id }) else { return }
        groceryItems[index].acquired.toggle()
        persist()
    }

    func addTimer(dishName: String, durationSec: Int, notes: String, startNow: Bool) {
        let duration = max(1, durationSec)
        let timer = DishTimer(
            id: UUID().uuidString,
            dishName: dishName,
            durationSec: duration,
            notes: notes,
            startedAt: startNow ? Date() : nil,
            remainingSec: duration
        )
        timers.insert(timer, at: 0)
        persist()
    }

    func updateTimer(_ timer: DishTimer) {
        guard let index = timers.firstIndex(where: { $0.id == timer.id }) else { return }
        timers[index] = timer
        persist()
    }

    func deleteTimer(id: String) {
        timers.removeAll { $0.id == id }
        persist()
    }

    func startTimer(id: String) {
        guard let index = timers.firstIndex(where: { $0.id == id }) else { return }
        if timers[index].remainingSec <= 0 {
            timers[index].remainingSec = timers[index].durationSec
        }
        timers[index].startedAt = Date()
        persist()
    }

    func pauseTimer(id: String) {
        guard let index = timers.firstIndex(where: { $0.id == id }) else { return }
        let now = Date()
        timers[index].remainingSec = timers[index].remaining(at: now)
        timers[index].startedAt = nil
        persist()
    }

    func settleExpiredTimers(at now: Date) {
        var changed = false
        var completedName: String?
        for index in timers.indices {
            if timers[index].startedAt != nil && timers[index].remaining(at: now) == 0 {
                timers[index].startedAt = nil
                timers[index].remainingSec = 0
                completedName = timers[index].dishName
                changed = true
            }
        }
        if changed {
            if activeNotifications {
                recentlyCompletedTimerName = completedName
            }
            persist()
        }
    }

    func clearCompletedBanner() {
        recentlyCompletedTimerName = nil
    }

    func setActiveNotifications(_ value: Bool) {
        activeNotifications = value
        persist()
    }

    func startTimerFromRecipe(_ recipe: Recipe) {
        addTimer(
            dishName: recipe.name,
            durationSec: max(60, recipe.cookMinutes * 60),
            notes: "From recipe ledger",
            startNow: true
        )
    }

    func planCook(recipe: Recipe, date: Date) {
        let meal = PlannedMeal(
            id: UUID().uuidString,
            recipeID: recipe.id,
            recipeName: recipe.name,
            plannedDate: date,
            isCompleted: false,
            usedIngredients: recipe.ingredients
        )
        plannedMeals.append(meal)
        for ingredient in missingIngredients(for: recipe) {
            enqueueGrocery(name: ingredient.name, category: ingredient.category, quantity: ingredient.quantity)
        }
        persist()
    }

    func completePlannedMeal(id: String) {
        guard let index = plannedMeals.firstIndex(where: { $0.id == id }) else { return }
        let meal = plannedMeals[index]
        for ingredient in meal.usedIngredients {
            if let pantryIndex = pantryItems.firstIndex(where: {
                AppStore.namesMatch($0.name, ingredient.name)
            }) {
                let next = pantryItems[pantryIndex].quantity - ingredient.quantity
                pantryItems[pantryIndex].quantity = next > 0 ? next : 0
            }
        }
        plannedMeals[index].isCompleted = true
        let minutes = recipe(id: meal.recipeID)?.cookMinutes ?? 0
        let record = CookRecord(
            id: UUID().uuidString,
            recipeID: meal.recipeID,
            recipeName: meal.recipeName,
            cookedAt: Date(),
            cookMinutes: minutes
        )
        cookHistory.insert(record, at: 0)
        persist()
    }

    func deletePlannedMeal(id: String) {
        plannedMeals.removeAll { $0.id == id }
        persist()
    }

    func resetAllData() {
        let keys = [
            Keys.pantryItems,
            Keys.favoriteRecipeIDs,
            Keys.lastViewedRecipeID,
            Keys.recipeSortOrder,
            Keys.groceryItems,
            Keys.lastSyncDate,
            Keys.timers,
            Keys.activeNotifications,
            Keys.plannedMeals,
            Keys.cookHistory,
            Keys.lastActivityDate,
            Keys.recipeNotes,
            Keys.lastMarketTrip
        ]
        for key in keys {
            defaults.removeObject(forKey: key)
        }
        pantryItems = []
        favoriteRecipeIDs = []
        lastViewedRecipeID = nil
        recipeSortOrder = "match"
        groceryItems = []
        lastSyncDate = nil
        timers = []
        activeNotifications = true
        plannedMeals = []
        cookHistory = []
        lastActivityDate = nil
        recentlyCompletedTimerName = nil
        recipeNotes = [:]
        lastMarketTrip = []
        NotificationCenter.default.post(name: Notification.Name("dataReset"), object: nil)
    }

    private var weekStart: Date {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: -6, to: start) ?? start
    }

    private func enqueueGrocery(name: String, category: String, quantity: Double) {
        if let index = groceryItems.firstIndex(where: {
            !$0.acquired && AppStore.namesMatch($0.name, name)
        }) {
            groceryItems[index].quantity += quantity
        } else {
            groceryItems.append(
                GroceryItem(
                    id: UUID().uuidString,
                    name: name,
                    category: category,
                    quantity: quantity,
                    acquired: false
                )
            )
        }
    }

    private func mergeIntoPantry(name: String, category: String, quantity: Double, unit: String) {
        if let index = pantryItems.firstIndex(where: { AppStore.namesMatch($0.name, name) }) {
            pantryItems[index].quantity += quantity
        } else {
            pantryItems.append(
                PantryItem(
                    id: UUID().uuidString,
                    name: name,
                    category: category,
                    quantity: quantity,
                    unit: unit
                )
            )
        }
    }

    private func persist() {
        lastActivityDate = Date()
        lastSyncDate = Date()
        save(pantryItems, key: Keys.pantryItems)
        save(favoriteRecipeIDs, key: Keys.favoriteRecipeIDs)
        saveOptionalString(lastViewedRecipeID, key: Keys.lastViewedRecipeID)
        defaults.set(recipeSortOrder, forKey: Keys.recipeSortOrder)
        save(groceryItems, key: Keys.groceryItems)
        saveOptionalDate(lastSyncDate, key: Keys.lastSyncDate)
        save(timers, key: Keys.timers)
        defaults.set(activeNotifications, forKey: Keys.activeNotifications)
        save(plannedMeals, key: Keys.plannedMeals)
        save(cookHistory, key: Keys.cookHistory)
        saveOptionalDate(lastActivityDate, key: Keys.lastActivityDate)
        save(recipeNotes, key: Keys.recipeNotes)
        if !groceryItems.isEmpty {
            lastMarketTrip = groceryItems.map {
                GroceryItem(
                    id: $0.id,
                    name: $0.name,
                    category: $0.category,
                    quantity: $0.quantity,
                    acquired: false
                )
            }
        }
        save(lastMarketTrip, key: Keys.lastMarketTrip)
    }

    private func load() {
        pantryItems = loadValue([PantryItem].self, key: Keys.pantryItems, fallback: [])
        favoriteRecipeIDs = loadValue([String].self, key: Keys.favoriteRecipeIDs, fallback: [])
        lastViewedRecipeID = defaults.string(forKey: Keys.lastViewedRecipeID)
        let storedOrder = defaults.string(forKey: Keys.recipeSortOrder) ?? "match"
        recipeSortOrder = ["match", "time", "name"].contains(storedOrder) ? storedOrder : "match"
        groceryItems = loadValue([GroceryItem].self, key: Keys.groceryItems, fallback: [])
        lastSyncDate = loadOptionalDate(key: Keys.lastSyncDate)
        timers = loadValue([DishTimer].self, key: Keys.timers, fallback: [])
        if defaults.object(forKey: Keys.activeNotifications) == nil {
            activeNotifications = true
        } else {
            activeNotifications = defaults.bool(forKey: Keys.activeNotifications)
        }
        plannedMeals = loadValue([PlannedMeal].self, key: Keys.plannedMeals, fallback: [])
        cookHistory = loadValue([CookRecord].self, key: Keys.cookHistory, fallback: [])
        lastActivityDate = loadOptionalDate(key: Keys.lastActivityDate)
        recipeNotes = loadValue([String: String].self, key: Keys.recipeNotes, fallback: [:])
        lastMarketTrip = loadValue([GroceryItem].self, key: Keys.lastMarketTrip, fallback: [])
        recentlyCompletedTimerName = nil
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? encoder.encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private func loadValue<T: Decodable>(_ type: T.Type, key: String, fallback: T) -> T {
        guard let data = defaults.data(forKey: key) else { return fallback }
        if let decoded = try? decoder.decode(type, from: data) {
            return decoded
        }
        return fallback
    }

    private func saveOptionalString(_ value: String?, key: String) {
        if let value {
            defaults.set(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    private func saveOptionalDate(_ value: Date?, key: String) {
        if let value, let data = try? encoder.encode(value) {
            defaults.set(data, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    private func loadOptionalDate(key: String) -> Date? {
        if let data = defaults.data(forKey: key), let date = try? decoder.decode(Date.self, from: data) {
            return date
        }
        if let interval = defaults.object(forKey: key) as? TimeInterval {
            return Date(timeIntervalSince1970: interval)
        }
        return nil
    }
}
