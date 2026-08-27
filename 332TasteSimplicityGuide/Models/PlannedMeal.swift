import Foundation

struct PlannedMeal: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var recipeID: String
    var recipeName: String
    var plannedDate: Date
    var isCompleted: Bool
    var usedIngredients: [RecipeIngredient]
}
