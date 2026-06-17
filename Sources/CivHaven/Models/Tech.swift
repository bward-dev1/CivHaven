import Foundation

enum TechID: String, Codable, CaseIterable {
    case pottery, animalHusbandry, archery, mining, bronzeWorking
    case horsebackRiding, writing, masonry

    var displayName: String {
        switch self {
        case .pottery:         return "Pottery"
        case .animalHusbandry: return "Animal Husbandry"
        case .archery:         return "Archery"
        case .mining:          return "Mining"
        case .bronzeWorking:   return "Bronze Working"
        case .horsebackRiding: return "Horseback Riding"
        case .writing:         return "Writing"
        case .masonry:         return "Masonry"
        }
    }

    var cost: Int {
        switch self {
        case .pottery, .mining:                 return 25
        case .animalHusbandry, .archery:        return 35
        case .bronzeWorking, .writing:          return 45
        case .horsebackRiding, .masonry:        return 55
        }
    }

    var prerequisites: [TechID] {
        switch self {
        case .bronzeWorking:   return [.mining]
        case .horsebackRiding: return [.animalHusbandry]
        case .writing:         return [.pottery]
        case .masonry:         return [.mining]
        default:               return []
        }
    }

    var blurb: String {
        switch self {
        case .pottery:         return "Foundations of storage and writing."
        case .animalHusbandry: return "Reveals horses; unlocks pastures."
        case .archery:         return "Unlocks the Archer."
        case .mining:          return "Unlocks mines and Bronze Working."
        case .bronzeWorking:   return "Unlocks the Spearman."
        case .horsebackRiding: return "Unlocks the Horseman."
        case .writing:         return "Boosts science output."
        case .masonry:         return "Stronger city defenses."
        }
    }
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
