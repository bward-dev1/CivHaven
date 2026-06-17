import Foundation

struct TechMeta {
    let name: String
    let cost: Int
    let prereqs: [TechID]
    let blurb: String
}

enum TechID: String, Codable, CaseIterable {
    // Ancient
    case pottery, animalHusbandry, archery, mining, sailing
    case bronzeWorking, ironWorking, masonry, writing, horsebackRiding
    // Classical
    case mathematics, optics, currency
    // Medieval
    case machinery, chivalry, navigation
    // Renaissance / industrial
    case gunpowder, rifling, industrialization, combustion, electronics

    var meta: TechMeta {
        switch self {
        case .pottery:          return .init(name: "Pottery",         cost: 25,  prereqs: [],                          blurb: "Granaries and the foundations of writing.")
        case .animalHusbandry:  return .init(name: "Animal Husbandry", cost: 35, prereqs: [],                          blurb: "Reveals horses; unlocks pastures.")
        case .archery:          return .init(name: "Archery",         cost: 35,  prereqs: [],                          blurb: "Unlocks the Archer.")
        case .mining:           return .init(name: "Mining",          cost: 25,  prereqs: [],                          blurb: "Unlocks mines and metalworking.")
        case .sailing:          return .init(name: "Sailing",         cost: 35,  prereqs: [.pottery],                  blurb: "Unlocks the Galley and coastal trade.")
        case .bronzeWorking:    return .init(name: "Bronze Working",  cost: 45,  prereqs: [.mining],                   blurb: "Unlocks the Spearman.")
        case .ironWorking:      return .init(name: "Iron Working",    cost: 55,  prereqs: [.bronzeWorking],            blurb: "Unlocks the Swordsman.")
        case .masonry:          return .init(name: "Masonry",         cost: 45,  prereqs: [.mining],                   blurb: "Stronger walls and stoneworks.")
        case .writing:          return .init(name: "Writing",         cost: 45,  prereqs: [.pottery],                  blurb: "Unlocks Libraries and faster science.")
        case .horsebackRiding:  return .init(name: "Horseback Riding", cost: 55, prereqs: [.animalHusbandry],          blurb: "Unlocks the Horseman.")
        case .mathematics:      return .init(name: "Mathematics",     cost: 70,  prereqs: [.writing],                  blurb: "Unlocks the Catapult.")
        case .optics:           return .init(name: "Optics",          cost: 70,  prereqs: [.sailing],                  blurb: "Unlocks the Trireme and ocean travel.")
        case .currency:         return .init(name: "Currency",        cost: 70,  prereqs: [.pottery, .bronzeWorking],  blurb: "Unlocks Markets and richer trade.")
        case .machinery:        return .init(name: "Machinery",       cost: 100, prereqs: [.ironWorking, .mathematics], blurb: "Unlocks the Crossbowman.")
        case .chivalry:         return .init(name: "Chivalry",        cost: 110, prereqs: [.horsebackRiding, .ironWorking], blurb: "Unlocks the Knight.")
        case .navigation:       return .init(name: "Navigation",      cost: 120, prereqs: [.optics],                  blurb: "Unlocks the Frigate.")
        case .gunpowder:        return .init(name: "Gunpowder",       cost: 150, prereqs: [.machinery, .chivalry],     blurb: "Unlocks the Musketman.")
        case .rifling:          return .init(name: "Rifling",         cost: 200, prereqs: [.gunpowder],                blurb: "Unlocks the Rifleman.")
        case .industrialization: return .init(name: "Industrialization", cost: 230, prereqs: [.currency, .navigation], blurb: "Unlocks the Ironclad and factories.")
        case .combustion:       return .init(name: "Combustion",      cost: 280, prereqs: [.industrialization],       blurb: "Unlocks the Destroyer.")
        case .electronics:      return .init(name: "Electronics",     cost: 300, prereqs: [.industrialization],       blurb: "Unlocks the Submarine.")
        }
    }

    var displayName: String { meta.name }
    var cost: Int { meta.cost }
    var prerequisites: [TechID] { meta.prereqs }
    var blurb: String { meta.blurb }
}

/// Per-player research progress.
struct TechState: Codable {
    var researched: Set<TechID> = []
    var current: TechID? = nil
    var progress: Int = 0

    func canResearch(_ tech: TechID) -> Bool {
        guard !researched.contains(tech) else { return false }
        return tech.prerequisites.allSatisfy { researched.contains($0) }
    }

    var available: [TechID] {
        TechID.allCases.filter { canResearch($0) }
    }
}
