import Foundation

struct DishTimer: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var dishName: String
    var durationSec: Int
    var notes: String
    var startedAt: Date?
    var remainingSec: Int

    var isRunning: Bool {
        startedAt != nil
    }

    func remaining(at now: Date) -> Int {
        guard let startedAt else { return max(0, remainingSec) }
        let elapsed = Int(now.timeIntervalSince(startedAt))
        let value = remainingSec - elapsed
        return value > 0 ? value : 0
    }

    func isCompleted(at now: Date) -> Bool {
        remaining(at: now) == 0
    }

    func allowsEdit(at now: Date) -> Bool {
        if isCompleted(at: now) {
            return false
        }
        if startedAt == nil {
            return true
        }
        return remaining(at: now) > 30
    }

    static func clock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let hours = s / 3600
        let minutes = (s % 3600) / 60
        let secs = s % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }
}

struct TimerPreset: Identifiable, Equatable {
    var id: String
    var name: String
    var minutes: Int
    var symbol: String

    var durationSec: Int { minutes * 60 }

    static let all: [TimerPreset] = [
        TimerPreset(id: "preset.eggs", name: "Eggs", minutes: 8, symbol: "circle.fill"),
        TimerPreset(id: "preset.pasta", name: "Pasta", minutes: 10, symbol: "fork.knife"),
        TimerPreset(id: "preset.rice", name: "Rice", minutes: 15, symbol: "circle.grid.3x3.fill"),
        TimerPreset(id: "preset.potato", name: "Potatoes", minutes: 20, symbol: "leaf.fill"),
        TimerPreset(id: "preset.steam", name: "Steam veg", minutes: 6, symbol: "drop.fill")
    ]
}
