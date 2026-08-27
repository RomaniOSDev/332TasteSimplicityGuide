import Foundation

struct CookRecord: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var recipeID: String
    var recipeName: String
    var cookedAt: Date
    var cookMinutes: Int
}

struct CookDayBucket: Identifiable, Equatable {
    var id: Date
    var label: String
    var count: Int
    var minutes: Int
}

struct RecipeCookStat: Identifiable, Equatable {
    var id: String
    var name: String
    var count: Int
    var minutes: Int
}

struct CategoryCount: Identifiable, Equatable {
    var id: String
    var name: String
    var count: Int
}

struct WeekDaySlot: Identifiable, Equatable {
    var id: Date
    var date: Date
    var meals: [PlannedMeal]
}
