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

    /// Movement points to enter this tile, or nil if impassable for land units.
    var moveCost: Int? {
        guard let base = terrain.moveCost else { return nil }
        return base + feature.extraMoveCost
    }

    var isSettleable: Bool {
        terrain.isSettleable && ownerCityID == nil
    }
}
