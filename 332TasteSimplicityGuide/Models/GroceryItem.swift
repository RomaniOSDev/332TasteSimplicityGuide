import Foundation

struct GroceryItem: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var name: String
    var category: String
    var quantity: Double
    var acquired: Bool
}
