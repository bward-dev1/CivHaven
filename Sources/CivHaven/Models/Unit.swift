import Foundation

/// Whether a unit travels over land or water. Drives pathfinding and where it can spawn.
enum UnitDomain: String, Codable {
    case land, sea
}

/// One row of unit balance data. Keeping it in a single table avoids a dozen
/// parallel switch statements as the roster grows.
struct UnitStats {
    let strength: Int       // combat strength (0 = non-combat)
    let movement: Int       // movement points per turn
    let cost: Int           // production hammers to build
    let domain: UnitDomain
    let range: Int          // ranged attack range (0 = melee only)
    let tech: TechID?       // tech required to build
    let symbol: String
}

enum UnitType: String, Codable, CaseIterable {
    // Civilian
    case settler, worker, scout
    // Ancient / classical land
    case warrior, spearman, archer, swordsman, horseman, catapult
    // Medieval / renaissance land
    case crossbowman, knight, musketman
    // Industrial land
    case rifleman
    // Naval
    case galley, trireme, frigate, ironclad, destroyer, submarine

    var stats: UnitStats {
        switch self {
        case .settler:     return .init(strength: 0,  movement: 2, cost: 60,  domain: .land, range: 0, tech: nil,              symbol: "⛺️")
        case .worker:      return .init(strength: 0,  movement: 2, cost: 30,  domain: .land, range: 0, tech: nil,              symbol: "🔧")
        case .scout:       return .init(strength: 5,  movement: 3, cost: 25,  domain: .land, range: 0, tech: nil,              symbol: "🧭")
        case .warrior:     return .init(strength: 8,  movement: 2, cost: 25,  domain: .land, range: 0, tech: nil,              symbol: "🗡️")
        case .spearman:    return .init(strength: 11, movement: 2, cost: 40,  domain: .land, range: 0, tech: .bronzeWorking,   symbol: "🔱")
        case .archer:      return .init(strength: 7,  movement: 2, cost: 35,  domain: .land, range: 2, tech: .archery,         symbol: "🏹")
        case .swordsman:   return .init(strength: 14, movement: 2, cost: 45,  domain: .land, range: 0, tech: .ironWorking,     symbol: "⚔️")
        case .horseman:    return .init(strength: 12, movement: 4, cost: 50,  domain: .land, range: 0, tech: .horsebackRiding, symbol: "🐎")
        case .catapult:    return .init(strength: 14, movement: 1, cost: 55,  domain: .land, range: 2, tech: .mathematics,     symbol: "🪨")
        case .crossbowman: return .init(strength: 18, movement: 2, cost: 60,  domain: .land, range: 2, tech: .machinery,       symbol: "🎯")
        case .knight:      return .init(strength: 20, movement: 4, cost: 80,  domain: .land, range: 0, tech: .chivalry,        symbol: "🐴")
        case .musketman:   return .init(strength: 24, movement: 2, cost: 90,  domain: .land, range: 0, tech: .gunpowder,       symbol: "🔫")
        case .rifleman:    return .init(strength: 34, movement: 2, cost: 120, domain: .land, range: 0, tech: .rifling,         symbol: "🪖")
        case .galley:      return .init(strength: 10, movement: 3, cost: 40,  domain: .sea,  range: 0, tech: .sailing,         symbol: "⛵️")
        case .trireme:     return .init(strength: 14, movement: 4, cost: 55,  domain: .sea,  range: 0, tech: .optics,          symbol: "🚣")
        case .frigate:     return .init(strength: 25, movement: 5, cost: 90,  domain: .sea,  range: 2, tech: .navigation,      symbol: "⛴️")
        case .ironclad:    return .init(strength: 45, movement: 5, cost: 120, domain: .sea,  range: 0, tech: .industrialization, symbol: "🛳️")
        case .destroyer:   return .init(strength: 60, movement: 6, cost: 160, domain: .sea,  range: 0, tech: .combustion,      symbol: "🚢")
        case .submarine:   return .init(strength: 50, movement: 5, cost: 150, domain: .sea,  range: 3, tech: .electronics,     symbol: "🤿")
        }
    }

    var strength: Int     { stats.strength }
    var maxMovement: Int  { stats.movement }
    var cost: Int         { stats.cost }
    var domain: UnitDomain { stats.domain }
    var range: Int        { stats.range }
    var requiredTech: TechID? { stats.tech }
    var symbol: String    { stats.symbol }
    var maxHP: Int { 100 }
    var isCombatant: Bool { strength > 0 }
    var isNaval: Bool { domain == .sea }

    var displayName: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }
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
