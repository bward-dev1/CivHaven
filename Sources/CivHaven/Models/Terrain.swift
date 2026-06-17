import SwiftUI

/// Base terrain type of a tile. Drives yields, movement cost and passability.
enum Terrain: String, Codable, CaseIterable {
    case ocean, coast, grassland, plains, desert, tundra, snow, hills, mountain

    var yields: Yields {
        switch self {
        case .ocean:     return Yields(food: 1, production: 0, gold: 1)
        case .coast:     return Yields(food: 1, production: 0, gold: 2)
        case .grassland: return Yields(food: 2, production: 0, gold: 0)
        case .plains:    return Yields(food: 1, production: 1, gold: 0)
        case .desert:    return Yields(food: 0, production: 0, gold: 0)
        case .tundra:    return Yields(food: 1, production: 0, gold: 0)
        case .snow:      return Yields(food: 0, production: 0, gold: 0)
        case .hills:     return Yields(food: 1, production: 2, gold: 0)
        case .mountain:  return Yields(food: 0, production: 0, gold: 0)
        }
    }

    /// Movement points needed to enter. `nil` means impassable to land units.
    var moveCost: Int? {
        switch self {
        case .mountain:        return nil
        case .ocean, .coast:   return nil      // land units only in this build
        case .hills:           return 2
        default:               return 1
        }
    }

    var isWater: Bool { self == .ocean || self == .coast }

    /// Can a city be founded here?
    var isSettleable: Bool {
        switch self {
        case .ocean, .coast, .mountain, .snow: return false
        default: return true
        }
    }

    var color: Color {
        switch self {
        case .ocean:     return Color(red: 0.10, green: 0.28, blue: 0.52)
        case .coast:     return Color(red: 0.20, green: 0.52, blue: 0.74)
        case .grassland: return Color(red: 0.40, green: 0.62, blue: 0.27)
        case .plains:    return Color(red: 0.72, green: 0.66, blue: 0.34)
        case .desert:    return Color(red: 0.86, green: 0.78, blue: 0.52)
        case .tundra:    return Color(red: 0.62, green: 0.66, blue: 0.58)
        case .snow:      return Color(red: 0.92, green: 0.94, blue: 0.96)
        case .hills:     return Color(red: 0.52, green: 0.55, blue: 0.30)
        case .mountain:  return Color(red: 0.45, green: 0.42, blue: 0.40)
        }
    }
}

/// Optional natural feature laid over a terrain.
enum Feature: String, Codable {
    case forest, jungle, none

    var extraYields: Yields {
        switch self {
        case .forest: return Yields(food: 0, production: 1, gold: 0)
        case .jungle: return Yields(food: 1, production: 0, gold: 0)
        case .none:   return .zero
        }
    }

    /// Extra movement points needed to enter (added to terrain cost).
    var extraMoveCost: Int {
        switch self {
        case .forest, .jungle: return 1
        case .none:            return 0
        }
    }
}

/// A bonus resource sitting on a tile.
enum Resource: String, Codable, CaseIterable {
    case wheat, cattle, iron, horses, gold, gems, fish

    var bonus: Yields {
        switch self {
        case .wheat:  return Yields(food: 1, production: 0, gold: 0)
        case .cattle: return Yields(food: 1, production: 0, gold: 0)
        case .iron:   return Yields(food: 0, production: 1, gold: 0)
        case .horses: return Yields(food: 0, production: 1, gold: 0)
        case .gold:   return Yields(food: 0, production: 0, gold: 3)
        case .gems:   return Yields(food: 0, production: 0, gold: 3)
        case .fish:   return Yields(food: 2, production: 0, gold: 0)
        }
    }

    var symbol: String {
        switch self {
        case .wheat:  return "🌾"
        case .cattle: return "🐄"
        case .iron:   return "⛏️"
        case .horses: return "🐎"
        case .gold:   return "🪙"
        case .gems:   return "💎"
        case .fish:   return "🐟"
        }
    }
}

struct Yields: Codable {
    var food: Int
    var production: Int
    var gold: Int

    static let zero = Yields(food: 0, production: 0, gold: 0)

    static func + (lhs: Yields, rhs: Yields) -> Yields {
        Yields(food: lhs.food + rhs.food,
               production: lhs.production + rhs.production,
               gold: lhs.gold + rhs.gold)
    }
}
