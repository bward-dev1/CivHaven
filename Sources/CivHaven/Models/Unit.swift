import Foundation

enum UnitType: String, Codable, CaseIterable {
    case settler, warrior, worker, archer, spearman, horseman

    var maxMovement: Int {
        switch self {
        case .horseman: return 4
        case .worker:   return 2
        default:        return 2
        }
    }

    var maxHP: Int { 100 }

    /// Base combat strength. Settlers/workers are non-combat (0).
    var strength: Int {
        switch self {
        case .settler, .worker: return 0
        case .warrior:          return 8
        case .spearman:         return 11
        case .archer:           return 7
        case .horseman:         return 12
        }
    }

    /// Ranged attack range (0 = melee only).
    var range: Int { self == .archer ? 2 : 0 }

    var isCombatant: Bool { strength > 0 }

    /// Production hammers required to build.
    var cost: Int {
        switch self {
        case .warrior:  return 25
        case .worker:   return 30
        case .settler:  return 50
        case .archer:   return 35
        case .spearman: return 40
        case .horseman: return 50
        }
    }

    /// Tech that must be researched before this unit can be built.
    var requiredTech: TechID? {
        switch self {
        case .archer:   return .archery
        case .spearman: return .bronzeWorking
        case .horseman: return .horsebackRiding
        default:        return nil
        }
    }

    var symbol: String {
        switch self {
        case .settler:  return "⛺️"
        case .warrior:  return "🗡️"
        case .worker:   return "🔨"
        case .archer:   return "🏹"
        case .spearman: return "🔱"
        case .horseman: return "🐎"
        }
    }
}

struct Unit: Codable, Identifiable {
    let id: UUID
    var type: UnitType
    var owner: Int          // player index
    var coord: HexCoord
    var hp: Int
    var movesLeft: Int
    var fortified: Bool = false

    init(type: UnitType, owner: Int, coord: HexCoord) {
        self.id = UUID()
        self.type = type
        self.owner = owner
        self.coord = coord
        self.hp = type.maxHP
        self.movesLeft = type.maxMovement
    }

    mutating func refresh() {
        movesLeft = type.maxMovement
    }
}
