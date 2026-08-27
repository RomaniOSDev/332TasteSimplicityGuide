import Foundation

struct PantryItem: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var name: String
    var category: String
    var quantity: Double
    var unit: String
    var expiresAt: Date?

    init(id: String, name: String, category: String, quantity: Double, unit: String, expiresAt: Date? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.quantity = quantity
        self.unit = unit
        self.expiresAt = expiresAt
    }

    enum CodingKeys: String, CodingKey {
        case id, name, category, quantity, unit, expiresAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(String.self, forKey: .category)
        quantity = try container.decode(Double.self, forKey: .quantity)
        unit = try container.decode(String.self, forKey: .unit)
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
    }

    func daysUntilExpiry(from now: Date = Date()) -> Int? {
        guard let expiresAt else { return nil }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: now)
        let end = calendar.startOfDay(for: expiresAt)
        return calendar.dateComponents([.day], from: start, to: end).day
    }

    var isEatFirst: Bool {
        guard quantity > 0, let days = daysUntilExpiry() else { return false }
        return days <= 3
    }

    var isExpired: Bool {
        guard quantity > 0, let days = daysUntilExpiry() else { return false }
        return days < 0
    }
}

enum PantryCatalog {
    static let categories = [
        "Produce",
        "Dairy",
        "Grains",
        "Protein",
        "Herbs",
        "Oils",
        "Staples",
        "Other"
    ]

    static let units = [
        "pcs",
        "g",
        "kg",
        "ml",
        "L",
        "cup",
        "tbsp",
        "tsp",
        "bunch"
    ]
}
