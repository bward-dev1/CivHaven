import Foundation

/// A single hex on the map.
struct Tile: Codable, Identifiable {
    var id: HexCoord { coord }
    let coord: HexCoord
    var terrain: Terrain
    var feature: Feature = .none
    var resource: Resource? = nil

    /// id of the city working/owning this tile, if any.
    var ownerCityID: UUID? = nil

    /// Total yields including feature and resource.
    var totalYields: Yields {
        var y = terrain.yields + feature.extraYields
        if let r = resource { y = y + r.bonus }
        return y
    }

    /// Movement points to enter this tile for a land unit, or nil if impassable.
    var moveCost: Int? {
        guard let base = terrain.moveCost else { return nil }
        return base + feature.extraMoveCost
    }

    /// Movement cost to enter this tile for a unit of the given domain.
    /// Land units use terrain cost; sea units traverse water only.
    func moveCost(for domain: UnitDomain) -> Int? {
        switch domain {
        case .land:
            return moveCost
        case .sea:
            return terrain.isWater ? 1 : nil
        }
    }

    var isWater: Bool { terrain.isWater }
    var isCoastal: Bool { terrain == .coast }

    var isSettleable: Bool {
        terrain.isSettleable && ownerCityID == nil
    }
}
