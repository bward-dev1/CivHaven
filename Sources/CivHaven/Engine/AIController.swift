import Foundation

/// A deliberately simple but coherent AI: settle early, then explore/expand and
/// attack the nearest enemy when it has a military edge.
enum AIController {
    static func takeTurn(player p: Int, state: GameState) {
        // 1. Choose research if idle.
        if state.player(p).tech.current == nil {
            if let pick = state.player(p).tech.available.min(by: { $0.cost < $1.cost }) {
                state.setResearch(pick, player: p)
            }
        }

        // 2. Set city production toward a balanced build order.
        for city in state.cities(ofPlayer: p) where city.queue == nil {
            let item = chooseProduction(for: city, player: p, state: state)
            state.setProduction(item, cityID: city.id)
        }

        // 3. Act with each unit.
        for unit in state.units(ofPlayer: p) {
            switch unit.type {
            case .settler:
                handleSettler(unit, player: p, state: state)
            case .worker:
                wander(unit, state: state)
            default:
                handleMilitary(unit, player: p, state: state)
            }
        }
    }

    private static func chooseProduction(for city: City, player p: Int, state: GameState) -> ProductionItem {
        let techs = state.player(p).tech.researched
        let myMilitary = state.units(ofPlayer: p).filter { $0.type.isCombatant }.count
        let cityCount = state.cities(ofPlayer: p).count

        if cityCount < 3 && city.population >= 2 {
            return .unit(.settler)
        }
        if myMilitary < cityCount + 1 {
            if techs.contains(.bronzeWorking) { return .unit(.spearman) }
            if techs.contains(.archery) { return .unit(.archer) }
            return .unit(.warrior)
        }
        if techs.contains(.writing) && !city.buildings.contains(.library) {
            return .building(.library)
        }
        if techs.contains(.pottery) && !city.buildings.contains(.granary) {
            return .building(.granary)
        }
        return .unit(.warrior)
    }

    private static func handleSettler(_ unit: Unit, player p: Int, state: GameState) {
        // Found here if it's a decent spot and not adjacent to an existing city.
        let tooClose = state.cities.contains { $0.coord.distance(to: unit.coord) <= 2 }
        if state.map[unit.coord]?.isSettleable == true && !tooClose {
            state.aiFound(unit.id)
            return
        }
        // Otherwise move toward open settleable land.
        if let target = nearestSettleSpot(from: unit.coord, state: state) {
            state.aiMove(unit.id, to: target)
        } else {
            wander(unit, state: state)
        }
    }

    private static func handleMilitary(_ unit: Unit, player p: Int, state: GameState) {
        // Find the nearest enemy unit or city.
        let enemies = state.units.filter { $0.owner != p } .map { $0.coord }
            + state.cities.filter { $0.owner != p }.map { $0.coord }
        guard let target = enemies.min(by: { $0.distance(to: unit.coord) < $1.distance(to: unit.coord) }) else {
            wander(unit, state: state)
            return
        }
        let dist = target.distance(to: unit.coord)
        // Defend home if no nearby threats and few units; else press the attack.
        if dist <= 6 {
            state.aiMove(unit.id, to: target)
        } else {
            wander(unit, state: state)
        }
    }

    private static func wander(_ unit: Unit, state: GameState) {
        let reachable = Pathfinder.reachable(from: unit.coord, budget: unit.movesLeft, map: state.map)
        guard let dest = reachable.keys.filter({ state.unit(at: $0) == nil }).randomElementStable(seed: unit.id.hashValue) else { return }
        state.aiMove(unit.id, to: dest)
    }

    private static func nearestSettleSpot(from coord: HexCoord, state: GameState) -> HexCoord? {
        let candidates = state.map.coords.filter { c in
            state.map[c]?.isSettleable == true &&
            !state.cities.contains { $0.coord.distance(to: c) <= 2 }
        }
        return candidates.min { $0.distance(to: coord) < $1.distance(to: coord) }
    }
}

private extension Array {
    /// Deterministic "random" pick so AI doesn't need a live RNG and stays replayable.
    func randomElementStable(seed: Int) -> Element? {
        guard !isEmpty else { return nil }
        let idx = abs(seed) % count
        return self[idx]
    }
}
