import SwiftUI
import Combine

/// The single source of truth for a game session. Observable so SwiftUI redraws.
final class GameState: ObservableObject {
    @Published private(set) var map: GameMap
    @Published private(set) var players: [Player]
    @Published private(set) var units: [Unit]
    @Published private(set) var cities: [City]
    @Published private(set) var turn: Int = 1
    @Published private(set) var currentPlayer: Int = 0
    @Published var log: [String] = []

    /// Tiles each player has ever seen (fog of war), keyed by player index.
    @Published private(set) var explored: [Set<HexCoord>]

    let humanPlayer = 0
    private var cityCountByPlayer: [Int: Int] = [:]
    private let fallbackCityNames = ["Haven", "Auroria", "Brightford", "Stonewatch", "Kingsreach",
                                     "Rivermill", "Oakhollow", "Stormvale", "Goldcrest", "Irongate"]

    /// World-unique wonders already built anywhere on the map.
    @Published private(set) var builtWonders: Set<WonderType> = []

    init(mapWidth: Int = 22, mapHeight: Int = 16, aiCount: Int = 2, seed: UInt64 = 12345,
         humanCivID: String? = nil) {
        let generated = GameMap.generate(width: mapWidth, height: mapHeight, seed: seed)
        self.map = generated

        // Deal each player a distinct civilization, drawn deterministically from the seed.
        var rng = SeededRNG(seed: seed ^ 0xC1F)
        var pool = Civilization.all
        for i in stride(from: pool.count - 1, to: 0, by: -1) {
            let j = Int(rng.next() % UInt64(i + 1))
            pool.swapAt(i, j)
        }
        func takeCiv(preferred: String?) -> Civilization {
            if let id = preferred, let idx = pool.firstIndex(where: { $0.id == id }) {
                return pool.remove(at: idx)
            }
            return pool.isEmpty ? Civilization.all[0] : pool.removeFirst()
        }

        let humanCiv = takeCiv(preferred: humanCivID)
        var players: [Player] = [
            Player(id: 0, name: "You — \(humanCiv.name)", isHuman: true,
                   colorHex: humanCiv.colorHex, civID: humanCiv.id)
        ]
        for i in 0..<aiCount {
            let civ = takeCiv(preferred: nil)
            players.append(Player(id: i + 1, name: "\(civ.leader) of \(civ.name)",
                                  isHuman: false, colorHex: civ.colorHex, civID: civ.id))
        }
        self.players = players
        self.explored = Array(repeating: [], count: players.count)
        self.units = []
        self.cities = []

        placeStartingUnits(seed: seed)
        revealAround(player: humanPlayer)
    }

    // MARK: - Wonder helpers

    /// Does this player own a wonder granting the given effect?
    private func playerOwnsWonder(_ p: Int, where predicate: (WonderType) -> Bool) -> Bool {
        cities.contains { $0.owner == p && $0.wonders.contains(where: predicate) }
    }

    // MARK: - Lookups

    func unit(at coord: HexCoord) -> Unit? { units.first { $0.coord == coord } }
    func city(at coord: HexCoord) -> City? { cities.first { $0.coord == coord } }
    func units(ofPlayer p: Int) -> [Unit] { units.filter { $0.owner == p } }
    func cities(ofPlayer p: Int) -> [City] { cities.filter { $0.owner == p } }
    func player(_ i: Int) -> Player { players[i] }

    func isVisible(_ coord: HexCoord) -> Bool { explored[humanPlayer].contains(coord) }

    // MARK: - Setup

    private func placeStartingUnits(seed: UInt64) {
        var rng = SeededRNG(seed: seed ^ 0xABCD)
        let landCoords = map.coords.filter { map[$0]?.terrain.isSettleable == true }
        guard !landCoords.isEmpty else { return }

        var used: [HexCoord] = []
        for p in 0..<players.count {
            // Pick a start far from existing starts.
            var best: HexCoord = landCoords[Int(rng.next() % UInt64(landCoords.count))]
            var bestScore = -1
            for _ in 0..<40 {
                let cand = landCoords[Int(rng.next() % UInt64(landCoords.count))]
                let minDist = used.map { $0.distance(to: cand) }.min() ?? 99
                if minDist > bestScore { bestScore = minDist; best = cand }
            }
            used.append(best)
            units.append(Unit(type: .settler, owner: p, coord: best))
            if let warriorSpot = best.neighbors.first(where: { map[$0]?.moveCost != nil && unit(at: $0) == nil }) {
                units.append(Unit(type: .warrior, owner: p, coord: warriorSpot))
            }
        }
    }

    // MARK: - Fog of war

    private func revealAround(player p: Int) {
        for u in units(ofPlayer: p) {
            for c in u.coord.withinRange(2) where map.contains(c) {
                explored[p].insert(c)
            }
        }
        for city in cities(ofPlayer: p) {
            for c in city.coord.withinRange(2) where map.contains(c) {
                explored[p].insert(c)
            }
        }
    }

    // MARK: - Player actions

    /// Move a unit toward a destination, spending movement points along the path.
    @discardableResult
    func moveUnit(_ id: UUID, to dest: HexCoord) -> Bool {
        guard let idx = units.firstIndex(where: { $0.id == id }) else { return false }
        var mover = units[idx]
        guard mover.movesLeft > 0 else { return false }
        let owner = mover.owner
        let domain = mover.type.domain

        let occupied = Set(units.filter { $0.id != id && $0.owner == owner }.map { $0.coord })
        guard let path = Pathfinder.path(from: mover.coord, to: dest, map: map, domain: domain, blocked: occupied) else { return false }

        for step in path {
            // Attack if an enemy unit/city occupies the next tile, then stop.
            if let enemy = unit(at: step), enemy.owner != owner {
                if mover.type.isCombatant { resolveCombat(attackerID: id, defenderCoord: step) }
                break
            }
            if let enemyCity = city(at: step), enemyCity.owner != owner {
                if mover.type.isCombatant { attackCity(attackerID: id, cityID: enemyCity.id) }
                break
            }
            guard let cost = map[step]?.moveCost(for: domain), mover.movesLeft >= 1 else { break }
            mover.coord = step
            mover.movesLeft = max(0, mover.movesLeft - cost)
            mover.fortified = false
            if let i = units.firstIndex(where: { $0.id == id }) { units[i] = mover }
        }

        revealAround(player: owner)
        objectWillChange.send()
        return true
    }

    func foundCity(with settlerID: UUID) {
        guard let idx = units.firstIndex(where: { $0.id == settlerID }),
              units[idx].type == .settler else { return }
        let settler = units[idx]
        guard map[settler.coord]?.isSettleable == true, city(at: settler.coord) == nil else {
            addLog("Can't found a city here.")
            return
        }
        let owner = settler.owner
        let names = players[owner].civ.cityNames.isEmpty ? fallbackCityNames : players[owner].civ.cityNames
        let n = cityCountByPlayer[owner, default: 0]
        cityCountByPlayer[owner] = n + 1
        let name = n < names.count ? names[n] : "\(names[n % names.count]) \(n / names.count + 1)"
        var city = City(name: name, owner: owner, coord: settler.coord)
        city.queue = .unit(.warrior)
        city.isCoastal = settler.coord.neighbors.contains { map[$0]?.isWater == true }
        claimTiles(for: &city)
        cities.append(city)
        units.remove(at: idx)
        addLog("\(players[settler.owner].name) founded \(name).")
        revealAround(player: settler.owner)
        objectWillChange.send()
    }

    private func claimTiles(for city: inout City) {
        for c in city.coord.withinRange(2) where map.contains(c) {
            if map[c]?.ownerCityID == nil {
                map[c]?.ownerCityID = city.id
            }
        }
        city.workedTiles = Set(city.coord.neighbors.filter { map[$0]?.ownerCityID == city.id })
    }

    func fortify(_ id: UUID) {
        guard let idx = units.firstIndex(where: { $0.id == id }) else { return }
        units[idx].fortified = true
        units[idx].movesLeft = 0
        objectWillChange.send()
    }

    func setProduction(_ item: ProductionItem, cityID: UUID) {
        guard let idx = cities.firstIndex(where: { $0.id == cityID }) else { return }
        cities[idx].queue = item
        objectWillChange.send()
    }

    func setResearch(_ tech: TechID, player p: Int) {
        guard players[p].tech.canResearch(tech) else { return }
        players[p].tech.current = tech
        objectWillChange.send()
    }

    // MARK: - Combat

    func resolveCombat(attackerID: UUID, defenderCoord: HexCoord) {
        guard let aIdx = units.firstIndex(where: { $0.id == attackerID }),
              let dIdx = units.firstIndex(where: { $0.coord == defenderCoord }) else { return }
        var attacker = units[aIdx]
        var defender = units[dIdx]

        let aStr = Double(attacker.type.strength) * (Double(attacker.hp) / 100.0)
        var dStr = Double(defender.type.strength) * (Double(defender.hp) / 100.0)
        if defender.fortified { dStr *= 1.25 }
        if let terr = map[defender.coord]?.terrain, terr == .hills { dStr *= 1.25 }

        let ratio = aStr / max(1.0, dStr)
        let dmgToDefender = Int((30.0 * ratio).clamped(to: 10...80))
        let dmgToAttacker = attacker.type.range > 0 ? 0 : Int((30.0 / ratio).clamped(to: 10...80))

        defender.hp -= dmgToDefender
        attacker.hp -= dmgToAttacker

        addLog("\(players[attacker.owner].name)'s \(attacker.type.rawValue) hit \(players[defender.owner].name)'s \(defender.type.rawValue).")

        if defender.hp <= 0 {
            units.remove(at: dIdx)
            addLog("\(players[defender.owner].name)'s \(defender.type.rawValue) was destroyed!")
            // Melee attacker advances into the tile.
            if attacker.hp > 0 && attacker.type.range == 0 {
                if let i = units.firstIndex(where: { $0.id == attackerID }) {
                    units[i].coord = defenderCoord
                }
            }
        } else if let i = units.firstIndex(where: { $0.id == defender.id }) {
            units[i] = defender
        }

        attacker.movesLeft = 0
        if attacker.hp <= 0 {
            units.removeAll { $0.id == attackerID }
        } else if let i = units.firstIndex(where: { $0.id == attackerID }) {
            units[i] = attacker
        }
        objectWillChange.send()
    }

    func attackCity(attackerID: UUID, cityID: UUID) {
        guard let aIdx = units.firstIndex(where: { $0.id == attackerID }),
              let cIdx = cities.firstIndex(where: { $0.id == cityID }) else { return }
        var attacker = units[aIdx]
        var city = cities[cIdx]

        let aStr = Double(attacker.type.strength) * (Double(attacker.hp) / 100.0)
        var defense = Double(city.defenseStrength)
        if playerOwnsWonder(city.owner, where: { $0.grantsDefense }) { defense *= 1.5 }
        let dmg = Int((28.0 * aStr / defense).clamped(to: 8...60))
        city.hp -= dmg
        attacker.movesLeft = 0
        addLog("\(players[attacker.owner].name) assaults \(city.name)!")

        if city.hp <= 0 {
            // Capture.
            let oldOwner = city.owner
            city.owner = attacker.owner
            city.hp = city.maxHP / 2
            city.population = max(1, city.population - 1)
            city.queue = nil
            for c in map.coords where map[c]?.ownerCityID == city.id {
                _ = c // ownership of tiles carries with the city id
            }
            if attacker.type.range == 0 {
                attacker.coord = city.coord
            }
            addLog("\(players[attacker.owner].name) captured \(city.name) from \(players[oldOwner].name)!")
        }

        cities[cIdx] = city
        if let i = units.firstIndex(where: { $0.id == attackerID }) { units[i] = attacker }
        checkDefeat()
        objectWillChange.send()
    }

    // MARK: - Turn cycle

    func endTurn() {
        // Process the human's end-of-turn, then run each AI, then advance.
        produceAndGrow(for: currentPlayer)
        advancePlayer()
    }

    private func advancePlayer() {
        repeat {
            currentPlayer += 1
            if currentPlayer >= players.count {
                currentPlayer = 0
                turn += 1
                refreshAllUnits()
            }
        } while players[currentPlayer].defeated

        if !players[currentPlayer].isHuman {
            runAITurn(player: currentPlayer)
            // AI immediately resolves and passes back.
            produceAndGrow(for: currentPlayer)
            advancePlayer()
        }
    }

    private func refreshAllUnits() {
        for i in units.indices {
            units[i].refresh()
            // Great Lighthouse: the owner's ships sail one tile farther.
            if units[i].type.isNaval, playerOwnsWonder(units[i].owner, where: { $0.grantsNavalMovement }) {
                units[i].movesLeft += 1
            }
        }
    }

    private func produceAndGrow(for p: Int) {
        // Science.
        var sciencePerTurn = 3
        for city in cities(ofPlayer: p) {
            if city.buildings.contains(.library) { sciencePerTurn += 2 }
            sciencePerTurn += city.population
            for w in city.wonders { sciencePerTurn += w.bonusScience }
        }
        players[p].science += sciencePerTurn
        advanceResearch(player: p, science: sciencePerTurn)

        // Cities: yields, growth, production.
        for idx in cities.indices where cities[idx].owner == p {
            var city = cities[idx]
            var food = 2, prod = 1, gold = 1
            for c in city.workedTiles {
                if let y = map[c]?.totalYields { food += y.food; prod += y.production; gold += y.gold }
            }
            if let y = map[city.coord]?.totalYields { food += y.food; prod += y.production; gold += y.gold }
            if city.buildings.contains(.granary) { food += 2 }
            for w in city.wonders {
                food += w.cityYields.food; prod += w.cityYields.production; gold += w.cityYields.gold
            }

            let surplus = food - city.population * 2
            city.foodStored += max(-city.population, surplus)
            if city.foodStored >= city.foodToGrow {
                city.foodStored = 0
                city.population += 1
                claimTiles(for: &city)
                if city.owner == humanPlayer { addLog("\(city.name) grew to size \(city.population).") }
            } else if city.foodStored < 0 {
                city.foodStored = 0
                if city.population > 1 { city.population -= 1 }
            }

            players[p].gold += gold
            city.hp = min(city.maxHP, city.hp + 5)  // regen

            // Production.
            if let item = city.queue {
                city.productionStored += prod
                if city.productionStored >= item.cost {
                    city.productionStored = 0
                    completeProduction(item, in: &city, player: p)
                }
            }
            cities[idx] = city
        }
        objectWillChange.send()
    }

    private func completeProduction(_ item: ProductionItem, in city: inout City, player p: Int) {
        switch item {
        case .unit(let type):
            let target: HexCoord?
            if type.domain == .sea {
                target = city.coord.neighbors.first { map[$0]?.isWater == true && unit(at: $0) == nil }
            } else if unit(at: city.coord) == nil {
                target = city.coord
            } else {
                target = city.coord.neighbors.first { map[$0]?.moveCost != nil && unit(at: $0) == nil }
            }
            if let t = target {
                units.append(Unit(type: type, owner: p, coord: t))
                if city.owner == humanPlayer { addLog("\(city.name) trained a \(type.displayName).") }
            } else {
                // No room to deploy — bank half the hammers toward the next attempt.
                city.productionStored = item.cost / 2
            }
            city.queue = .unit(.warrior)
        case .building(let b):
            city.buildings.insert(b)
            if city.owner == humanPlayer { addLog("\(city.name) built \(b.displayName).") }
            city.queue = nil
        case .wonder(let w):
            guard !builtWonders.contains(w) else {
                if city.owner == humanPlayer { addLog("\(w.displayName) was already built elsewhere.") }
                city.queue = nil
                return
            }
            city.wonders.insert(w)
            builtWonders.insert(w)
            addLog("✨ \(players[p].name) completed \(w.displayName)!")
            city.queue = nil
        }
    }

    private func advanceResearch(player p: Int, science: Int) {
        guard let current = players[p].tech.current else { return }
        players[p].tech.progress += science
        if players[p].tech.progress >= current.cost {
            players[p].tech.researched.insert(current)
            players[p].tech.progress = 0
            players[p].tech.current = nil
            if p == humanPlayer { addLog("Researched \(current.displayName)!") }
        }
    }

    private func checkDefeat() {
        for i in players.indices {
            if cities(ofPlayer: i).isEmpty && units(ofPlayer: i).isEmpty && !players[i].defeated {
                players[i].defeated = true
                addLog("\(players[i].name) has been eliminated.")
            }
        }
    }

    // MARK: - AI

    private func runAITurn(player p: Int) {
        AIController.takeTurn(player: p, state: self)
    }

    // Internal mutators the AI uses.
    func aiMove(_ id: UUID, to dest: HexCoord) { moveUnit(id, to: dest) }
    func aiFound(_ id: UUID) { foundCity(with: id) }

    // MARK: - Log

    func addLog(_ message: String) {
        log.insert("T\(turn): \(message)", at: 0)
        if log.count > 60 { log.removeLast() }
    }

    var isGameOver: Bool {
        players.filter { !$0.defeated }.count <= 1
    }

    var winner: Player? {
        let alive = players.filter { !$0.defeated }
        return alive.count == 1 ? alive.first : nil
    }
}

// MARK: - Small helpers

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
