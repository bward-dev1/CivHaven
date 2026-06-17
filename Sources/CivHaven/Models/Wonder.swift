import Foundation

/// World wonders — globally unique buildings. The monuments are real public-domain
/// history; their game effects are original to CivHaven.
enum WonderType: String, Codable, CaseIterable {
    case stonehenge, pyramids, hangingGardens, greatLibrary, oracle
    case colossus, greatLighthouse, terracottaArmy, petra, greatWall

    var displayName: String {
        switch self {
        case .stonehenge:     return "Stonehenge"
        case .pyramids:       return "The Pyramids"
        case .hangingGardens: return "Hanging Gardens"
        case .greatLibrary:   return "Great Library"
        case .oracle:         return "The Oracle"
        case .colossus:       return "Colossus"
        case .greatLighthouse: return "Great Lighthouse"
        case .terracottaArmy: return "Terracotta Army"
        case .petra:          return "Petra"
        case .greatWall:      return "Great Wall"
        }
    }

    var cost: Int {
        switch self {
        case .stonehenge:     return 120
        case .pyramids:       return 180
        case .hangingGardens: return 170
        case .greatLibrary:   return 200
        case .oracle:         return 150
        case .colossus:       return 150
        case .greatLighthouse: return 190
        case .terracottaArmy: return 220
        case .petra:          return 180
        case .greatWall:      return 200
        }
    }

    var requiredTech: TechID? {
        switch self {
        case .stonehenge:     return nil
        case .pyramids:       return .masonry
        case .hangingGardens: return .pottery
        case .greatLibrary:   return .writing
        case .oracle:         return .writing
        case .colossus:       return .sailing
        case .greatLighthouse: return .optics
        case .terracottaArmy: return .ironWorking
        case .petra:          return .currency
        case .greatWall:      return .masonry
        }
    }

    /// Must the host city be on the coast?
    var requiresCoast: Bool {
        self == .colossus || self == .greatLighthouse
    }

    /// Per-turn yields added to the host city.
    var cityYields: Yields {
        switch self {
        case .stonehenge:     return Yields(food: 0, production: 0, gold: 2)
        case .pyramids:       return Yields(food: 0, production: 3, gold: 0)
        case .hangingGardens: return Yields(food: 3, production: 0, gold: 0)
        case .colossus:       return Yields(food: 0, production: 0, gold: 3)
        case .terracottaArmy: return Yields(food: 0, production: 2, gold: 0)
        case .petra:          return Yields(food: 2, production: 0, gold: 2)
        default:              return .zero
        }
    }

    /// Per-turn science added to the host city.
    var bonusScience: Int {
        switch self {
        case .greatLibrary: return 3
        case .oracle:       return 2
        default:            return 0
        }
    }

    /// Naval units of the owner gain +1 movement.
    var grantsNavalMovement: Bool { self == .greatLighthouse }

    /// The owner's cities get +50% defense.
    var grantsDefense: Bool { self == .greatWall }

    var blurb: String {
        switch self {
        case .stonehenge:     return "An ancient circle of standing stones. +2 gold here."
        case .pyramids:       return "Monumental tombs that drive vast works. +3 production here."
        case .hangingGardens: return "Terraced gardens of a great river city. +3 food here."
        case .greatLibrary:   return "A hall of all the world's knowledge. +3 science here."
        case .oracle:         return "A revered seat of prophecy. +2 science here."
        case .colossus:       return "A harbor giant of bronze. +3 gold here. (Coastal)"
        case .greatLighthouse: return "A towering beacon. Your ships gain +1 movement. (Coastal)"
        case .terracottaArmy: return "An army sculpted in clay. +2 production here."
        case .petra:          return "A city carved from desert rock. +2 food and +2 gold here."
        case .greatWall:      return "A vast frontier rampart. Your cities gain +50% defense."
        }
    }
}
