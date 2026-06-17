import Foundation

/// Stores all tiles and provides procedural generation.
struct GameMap: Codable {
    let width: Int
    let height: Int
    private(set) var tiles: [HexCoord: Tile]

    /// All valid coordinates in a rectangular-ish hex layout.
    var coords: [HexCoord] { Array(tiles.keys) }

    subscript(_ coord: HexCoord) -> Tile? {
        get { tiles[coord] }
        set { if let nv = newValue { tiles[coord] = nv } }
    }

    func contains(_ coord: HexCoord) -> Bool { tiles[coord] != nil }

    /// Generate a map using value-noise-ish elevation + latitude bands.
    static func generate(width: Int, height: Int, seed: UInt64) -> GameMap {
        var rng = SeededRNG(seed: seed)
        var tiles: [HexCoord: Tile] = [:]

        // Build the coordinate set first (offset rows so it tiles nicely).
        var allCoords: [HexCoord] = []
        for row in 0..<height {
            let rOffset = -(row / 2)
            for col in 0..<width {
                allCoords.append(HexCoord(col + rOffset, row))
            }
        }

        // Random elevation peaks; elevation = sum of falloffs from peaks.
        let peakCount = max(4, (width * height) / 40)
        let peaks: [(HexCoord, Double)] = (0..<peakCount).map { _ in
            let c = allCoords[Int(rng.next() % UInt64(allCoords.count))]
            return (c, Double(rng.next() % 100) / 100.0 * 0.8 + 0.2)
        }

        func elevation(_ c: HexCoord) -> Double {
            var e = 0.0
            for (p, strength) in peaks {
                let d = Double(c.distance(to: p))
                e += strength * exp(-d * d / 18.0)
            }
            return e
        }

        let maxRow = Double(height - 1)
        for c in allCoords {
            let e = elevation(c)
            let lat = abs(Double(c.r) / maxRow - 0.5) * 2.0  // 0 equator → 1 pole
            var terrain: Terrain
            if e < 0.18 {
                terrain = .ocean
            } else if e < 0.28 {
                terrain = .coast
            } else if e > 0.95 {
                terrain = .mountain
            } else if e > 0.72 {
                terrain = .hills
            } else {
                // Land biome by latitude + a little noise.
                let n = Double(rng.next() % 100) / 100.0
                if lat > 0.82 {
                    terrain = .snow
                } else if lat > 0.62 {
                    terrain = .tundra
                } else if lat < 0.25 && n < 0.30 {
                    terrain = .desert
                } else if n < 0.55 {
                    terrain = .grassland
                } else {
                    terrain = .plains
                }
            }

            var tile = Tile(coord: c, terrain: terrain)

            // Features on temperate land.
            if !terrain.isWater && terrain != .mountain && terrain != .snow {
                let n = rng.next() % 100
                if (terrain == .grassland || terrain == .plains) && n < 22 {
                    tile.feature = lat < 0.30 ? .jungle : .forest
                } else if terrain == .hills && n < 18 {
                    tile.feature = .forest
                }
            }

            // Resources, sparsely.
            if rng.next() % 100 < 9 {
                tile.resource = resourceFor(terrain: terrain, rng: &rng)
            }

            tiles[c] = tile
        }

        return GameMap(width: width, height: height, tiles: tiles)
    }

    private static func resourceFor(terrain: Terrain, rng: inout SeededRNG) -> Resource? {
        switch terrain {
        case .ocean, .coast:        return rng.next() % 2 == 0 ? .fish : nil
        case .grassland:            return [.cattle, .wheat].randomPick(&rng)
        case .plains:               return [.wheat, .horses].randomPick(&rng)
        case .hills:                return [.iron, .gold, .gems].randomPick(&rng)
        case .desert:               return rng.next() % 3 == 0 ? .gold : nil
        case .tundra:               return rng.next() % 3 == 0 ? .iron : nil
        default:                    return nil
        }
    }
}

/// Deterministic splittable RNG so the same seed → same map (good for replays/tests).
struct SeededRNG: Codable {
    private var state: UInt64
    init(seed: UInt64) { state = seed != 0 ? seed : 0x9E3779B97F4A7C15 }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

private extension Array where Element == Resource {
    func randomPick(_ rng: inout SeededRNG) -> Resource? {
        guard !isEmpty else { return nil }
        return self[Int(rng.next() % UInt64(count))]
    }
}
