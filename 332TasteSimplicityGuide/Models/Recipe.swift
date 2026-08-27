import Foundation

struct RecipeIngredient: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var name: String
    var quantity: Double
    var unit: String
    var category: String
}

struct Recipe: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var name: String
    var cookMinutes: Int
    var servings: Int
    var symbolName: String
    var blurb: String
    var ingredients: [RecipeIngredient]
    var steps: [String]
}

extension Recipe {
    static let catalog: [Recipe] = [
        Recipe(
            id: "recipe.tomato-basil-pasta",
            name: "Tomato Basil Pasta",
            cookMinutes: 25,
            servings: 2,
            symbolName: "leaf.fill",
            blurb: "A navy-pot classic: ripe tomato, torn basil, and a slick of olive oil.",
            ingredients: [
                RecipeIngredient(id: "tbp.tomato", name: "Tomato", quantity: 4, unit: "pcs", category: "Produce"),
                RecipeIngredient(id: "tbp.basil", name: "Basil", quantity: 1, unit: "bunch", category: "Herbs"),
                RecipeIngredient(id: "tbp.pasta", name: "Pasta", quantity: 200, unit: "g", category: "Grains"),
                RecipeIngredient(id: "tbp.garlic", name: "Garlic", quantity: 3, unit: "pcs", category: "Produce"),
                RecipeIngredient(id: "tbp.oil", name: "Olive Oil", quantity: 2, unit: "tbsp", category: "Oils"),
                RecipeIngredient(id: "tbp.parmesan", name: "Parmesan", quantity: 40, unit: "g", category: "Dairy"),
                RecipeIngredient(id: "tbp.salt", name: "Salt", quantity: 1, unit: "tsp", category: "Staples")
            ],
            steps: [
                "Boil a pot of salted water and cook the pasta until just tender.",
                "Warm olive oil in a wide pan and soften sliced garlic without browning.",
                "Add chopped tomato and a pinch of salt; simmer until jammy.",
                "Toss drained pasta with the sauce and a splash of cooking water.",
                "Tear basil over the top and finish with shaved parmesan."
            ]
        ),
        Recipe(
            id: "recipe.lentil-soup",
            name: "Lentil Soup",
            cookMinutes: 40,
            servings: 4,
            symbolName: "flame.fill",
            blurb: "A deep pot of lentils, sweet carrot, and cumin for a workshop supper.",
            ingredients: [
                RecipeIngredient(id: "ls.lentils", name: "Lentils", quantity: 200, unit: "g", category: "Protein"),
                RecipeIngredient(id: "ls.onion", name: "Onion", quantity: 1, unit: "pcs", category: "Produce"),
                RecipeIngredient(id: "ls.carrot", name: "Carrot", quantity: 2, unit: "pcs", category: "Produce"),
                RecipeIngredient(id: "ls.garlic", name: "Garlic", quantity: 2, unit: "pcs", category: "Produce"),
                RecipeIngredient(id: "ls.tomato", name: "Tomato", quantity: 2, unit: "pcs", category: "Produce"),
                RecipeIngredient(id: "ls.cumin", name: "Cumin", quantity: 1, unit: "tsp", category: "Staples"),
                RecipeIngredient(id: "ls.oil", name: "Olive Oil", quantity: 1, unit: "tbsp", category: "Oils"),
                RecipeIngredient(id: "ls.salt", name: "Salt", quantity: 1, unit: "tsp", category: "Staples")
            ],
            steps: [
                "Rinse lentils until the water runs clear.",
                "Sweat onion, carrot, and garlic in olive oil until fragrant.",
                "Stir in cumin, chopped tomato, lentils, and water to cover by two fingers.",
                "Simmer gently until lentils are soft, 25 to 30 minutes.",
                "Season with salt and mash a ladleful against the pot for body."
            ]
        ),
        Recipe(
            id: "recipe.herb-omelette",
            name: "Herb Omelette",
            cookMinutes: 10,
            servings: 1,
            symbolName: "leaf.circle.fill",
            blurb: "Eggs folded around basil and parsley — a fast herb-workshop breakfast.",
            ingredients: [
                RecipeIngredient(id: "ho.eggs", name: "Eggs", quantity: 3, unit: "pcs", category: "Protein"),
                RecipeIngredient(id: "ho.basil", name: "Basil", quantity: 1, unit: "bunch", category: "Herbs"),
                RecipeIngredient(id: "ho.parsley", name: "Parsley", quantity: 1, unit: "bunch", category: "Herbs"),
                RecipeIngredient(id: "ho.butter", name: "Butter", quantity: 1, unit: "tbsp", category: "Dairy"),
                RecipeIngredient(id: "ho.cheese", name: "Cheese", quantity: 30, unit: "g", category: "Dairy"),
                RecipeIngredient(id: "ho.salt", name: "Salt", quantity: 0.5, unit: "tsp", category: "Staples"),
                RecipeIngredient(id: "ho.pepper", name: "Pepper", quantity: 0.25, unit: "tsp", category: "Staples")
            ],
            steps: [
                "Beat eggs with salt and pepper until just blended.",
                "Chop basil and parsley; keep a few leaves whole for the plate.",
                "Melt butter in a warm pan and pour in the eggs.",
                "Scatter herbs and cheese, then fold the omelette while still glossy.",
                "Slide onto a warm plate and rest ten seconds before cutting."
            ]
        ),
        Recipe(
            id: "recipe.veggie-stir-fry",
            name: "Veggie Stir Fry",
            cookMinutes: 20,
            servings: 2,
            symbolName: "fork.knife",
            blurb: "Hot pan, crisp broccoli, and a soy glaze over steamed rice.",
            ingredients: [
                RecipeIngredient(id: "vs.broccoli", name: "Broccoli", quantity: 1, unit: "pcs", category: "Produce"),
                RecipeIngredient(id: "vs.carrot", name: "Carrot", quantity: 2, unit: "pcs", category: "Produce"),
                RecipeIngredient(id: "vs.pepper", name: "Bell Pepper", quantity: 1, unit: "pcs", category: "Produce"),
                RecipeIngredient(id: "vs.garlic", name: "Garlic", quantity: 2, unit: "pcs", category: "Produce"),
                RecipeIngredient(id: "vs.soy", name: "Soy Sauce", quantity: 2, unit: "tbsp", category: "Staples"),
                RecipeIngredient(id: "vs.rice", name: "Rice", quantity: 150, unit: "g", category: "Grains"),
                RecipeIngredient(id: "vs.oil", name: "Olive Oil", quantity: 1, unit: "tbsp", category: "Oils")
            ],
            steps: [
                "Rinse rice and steam until tender; keep covered.",
                "Cut broccoli, carrot, and bell pepper into bite-size pieces.",
                "Heat oil in a wide pan and stir-fry garlic for a few seconds.",
                "Add vegetables and toss over high heat until bright and crisp.",
                "Splash in soy sauce, toss once more, and serve over rice."
            ]
        ),
        Recipe(
            id: "recipe.garlic-potatoes",
            name: "Garlic Potatoes",
            cookMinutes: 35,
            servings: 3,
            symbolName: "sparkle",
            blurb: "Roasted potato wedges stamped with garlic, rosemary, and oil.",
            ingredients: [
                RecipeIngredient(id: "gp.potato", name: "Potato", quantity: 600, unit: "g", category: "Produce"),
                RecipeIngredient(id: "gp.garlic", name: "Garlic", quantity: 4, unit: "pcs", category: "Produce"),
                RecipeIngredient(id: "gp.oil", name: "Olive Oil", quantity: 2, unit: "tbsp", category: "Oils"),
                RecipeIngredient(id: "gp.rosemary", name: "Rosemary", quantity: 1, unit: "bunch", category: "Herbs"),
                RecipeIngredient(id: "gp.salt", name: "Salt", quantity: 1, unit: "tsp", category: "Staples"),
                RecipeIngredient(id: "gp.pepper", name: "Pepper", quantity: 0.5, unit: "tsp", category: "Staples")
            ],
            steps: [
                "Heat the oven and cut potatoes into thick wedges.",
                "Toss with olive oil, crushed garlic, salt, and pepper.",
                "Spread on a tray and scatter rosemary sprigs.",
                "Roast until the edges are deep gold and the centers yield.",
                "Rest two minutes, then serve with an extra pinch of salt."
            ]
        ),
        Recipe(
            id: "recipe.chickpea-salad",
            name: "Chickpea Salad",
            cookMinutes: 15,
            servings: 2,
            symbolName: "circle.grid.3x3.fill",
            blurb: "A cool ledger bowl: chickpeas, tomato, cucumber, and lemon.",
            ingredients: [
                RecipeIngredient(id: "cs.chickpeas", name: "Chickpeas", quantity: 240, unit: "g", category: "Protein"),
                RecipeIngredient(id: "cs.tomato", name: "Tomato", quantity: 2, unit: "pcs", category: "Produce"),
                RecipeIngredient(id: "cs.cucumber", name: "Cucumber", quantity: 1, unit: "pcs", category: "Produce"),
                RecipeIngredient(id: "cs.onion", name: "Onion", quantity: 0.5, unit: "pcs", category: "Produce"),
                RecipeIngredient(id: "cs.oil", name: "Olive Oil", quantity: 2, unit: "tbsp", category: "Oils"),
                RecipeIngredient(id: "cs.lemon", name: "Lemon", quantity: 1, unit: "pcs", category: "Produce"),
                RecipeIngredient(id: "cs.parsley", name: "Parsley", quantity: 1, unit: "bunch", category: "Herbs"),
                RecipeIngredient(id: "cs.salt", name: "Salt", quantity: 0.5, unit: "tsp", category: "Staples")
            ],
            steps: [
                "Drain and rinse chickpeas; shake dry.",
                "Dice tomato and cucumber; slice onion thinly.",
                "Toss everything with olive oil, lemon juice, and salt.",
                "Fold in chopped parsley.",
                "Rest five minutes so the dressing settles into the chickpeas."
            ]
        ),
        Recipe(
            id: "recipe.simple-risotto",
            name: "Simple Risotto",
            cookMinutes: 30,
            servings: 2,
            symbolName: "drop.fill",
            blurb: "Slow-stirred rice with onion, broth, butter, and parmesan.",
            ingredients: [
                RecipeIngredient(id: "sr.rice", name: "Rice", quantity: 180, unit: "g", category: "Grains"),
                RecipeIngredient(id: "sr.onion", name: "Onion", quantity: 1, unit: "pcs", category: "Produce"),
                RecipeIngredient(id: "sr.garlic", name: "Garlic", quantity: 1, unit: "pcs", category: "Produce"),
                RecipeIngredient(id: "sr.butter", name: "Butter", quantity: 2, unit: "tbsp", category: "Dairy"),
                RecipeIngredient(id: "sr.parmesan", name: "Parmesan", quantity: 50, unit: "g", category: "Dairy"),
                RecipeIngredient(id: "sr.broth", name: "Broth", quantity: 700, unit: "ml", category: "Staples"),
                RecipeIngredient(id: "sr.salt", name: "Salt", quantity: 0.5, unit: "tsp", category: "Staples")
            ],
            steps: [
                "Keep broth warm in a small pot.",
                "Melt half the butter and soften onion and garlic.",
                "Toast the rice until the grains look glassy.",
                "Add broth a ladle at a time, stirring until each is absorbed.",
                "Finish with remaining butter, parmesan, and salt; rest one minute."
            ]
        ),
        Recipe(
            id: "recipe.rice-bowl",
            name: "Rice Bowl",
            cookMinutes: 20,
            servings: 1,
            symbolName: "square.stack.fill",
            blurb: "A stacked bowl of rice, egg, carrot, and broccoli with soy.",
            ingredients: [
                RecipeIngredient(id: "rb.rice", name: "Rice", quantity: 120, unit: "g", category: "Grains"),
                RecipeIngredient(id: "rb.egg", name: "Eggs", quantity: 1, unit: "pcs", category: "Protein"),
                RecipeIngredient(id: "rb.carrot", name: "Carrot", quantity: 1, unit: "pcs", category: "Produce"),
                RecipeIngredient(id: "rb.broccoli", name: "Broccoli", quantity: 0.5, unit: "pcs", category: "Produce"),
                RecipeIngredient(id: "rb.soy", name: "Soy Sauce", quantity: 1, unit: "tbsp", category: "Staples"),
                RecipeIngredient(id: "rb.sesame", name: "Sesame", quantity: 1, unit: "tsp", category: "Staples"),
                RecipeIngredient(id: "rb.garlic", name: "Garlic", quantity: 1, unit: "pcs", category: "Produce")
            ],
            steps: [
                "Steam rice until fluffy and keep covered.",
                "Blanch broccoli and carrot until just tender.",
                "Fry an egg with a little garlic until the edges crisp.",
                "Assemble rice, vegetables, and egg in a deep bowl.",
                "Spoon soy sauce over the top and dust with sesame."
            ]
        )
    ]
}

enum IngredientSwap {
    private static let pairs: [[String]] = [
        ["Basil", "Parsley"],
        ["Parsley", "Rosemary"],
        ["Parmesan", "Cheese"],
        ["Broccoli", "Bell Pepper"],
        ["Broccoli", "Carrot"],
        ["Chickpeas", "Lentils"],
        ["Butter", "Olive Oil"],
        ["Onion", "Garlic"]
    ]

    static func candidates(for name: String) -> [String] {
        pairs.flatMap { pair -> [String] in
            if pair.contains(where: { AppStore.namesMatch($0, name) }) {
                return pair.filter { !AppStore.namesMatch($0, name) }
            }
            return []
        }
    }
}
