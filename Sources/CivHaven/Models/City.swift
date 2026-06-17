import Foundation

/// What a city is currently building.
enum ProductionItem: Codable, Equatable {
    case unit(UnitType)
    case building(BuildingType)
    case wonder(WonderType)

    var cost: Int {
        switch self {
        case .unit(let u):     return u.cost
        case .building(let b): return b.cost
        case .wonder(let w):   return w.cost
        }
    }

    var label: String {
        switch self {
        case .unit(let u):     return u.displayName
        case .building(let b): return b.displayName
        case .wonder(let w):   return w.displayName
        }
    }
}

enum BuildingType: String, Codable, CaseIterable {
    case granary, walls, library, barracks

    var cost: Int {
        switch self {
        case .granary:  return 40
        case .walls:    return 45
        case .library:  return 50
        case .barracks: return 45
        }
    }

    var displayName: String { rawValue.capitalized }

    var requiredTech: TechID? {
        switch self {
        case .granary:  return .pottery
        case .walls:    return .masonry
        case .library:  return .writing
        case .barracks: return .bronzeWorking
        }
    }

    var blurb: String {
        switch self {
        case .granary:  return "+2 food per turn."
        case .walls:    return "+50% city defense."
        case .library:  return "+2 science per turn."
        case .barracks: return "New units start with a promotion."
        }
    }
}

struct City: Codable, Identifiable {
    let id: UUID
    var name: String
    var owner: Int
    var coord: HexCoord
    var population: Int
    var hp: Int
    var maxHP: Int
    var foodStored: Int = 0
    var productionStored: Int = 0
    var queue: ProductionItem?
    var buildings: Set<BuildingType> = []
    var wonders: Set<WonderType> = []
    var workedTiles: Set<HexCoord> = []
    var isCoastal: Bool = false

    init(name: String, owner: Int, coord: HexCoord) {
        self.id = UUID()
        self.name = name
        self.owner = owner
        self.coord = coord
        self.population = 1
        self.maxHP = 100
        self.hp = 100
    }

    /// Food required to grow to the next population point.
    var foodToGrow: Int { 15 + (population - 1) * 8 }

    var defenseStrength: Int {
        var base = 6 + population
        if buildings.contains(.walls) { base += base / 2 }
        return base
    }
}
