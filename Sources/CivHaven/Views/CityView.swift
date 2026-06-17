import SwiftUI

/// City management sheet: pick what to build, see yields and buildings.
struct CityView: View {
    @ObservedObject var game: GameState
    let cityID: UUID
    @Environment(\.dismiss) private var dismiss

    private var city: City? { game.cities.first(where: { $0.id == cityID }) }

    var body: some View {
        NavigationStack {
            if let city = city {
                List {
                    Section("Overview") {
                        row("Population", "\(city.population)")
                        row("Health", "\(city.hp)/\(city.maxHP)")
                        row("Food", "\(city.foodStored)/\(city.foodToGrow)")
                        row("Defense", "\(city.defenseStrength)")
                    }

                    Section("Producing") {
                        if let q = city.queue {
                            HStack {
                                Text(q.label)
                                Spacer()
                                Text("\(city.productionStored)/\(q.cost) ⚒")
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("Nothing — choose below").foregroundColor(.orange)
                        }
                    }

                    Section("Land Units") {
                        ForEach(buildableUnits(naval: false), id: \.self) { type in
                            buildButton(label: "\(type.symbol) \(type.displayName)",
                                        cost: type.cost,
                                        item: .unit(type))
                        }
                    }

                    if city.isCoastal {
                        Section("Naval Units") {
                            let ships = buildableUnits(naval: true)
                            if ships.isEmpty {
                                Text("Research Sailing to build ships.").font(.caption).foregroundColor(.secondary)
                            }
                            ForEach(ships, id: \.self) { type in
                                buildButton(label: "\(type.symbol) \(type.displayName)",
                                            cost: type.cost,
                                            item: .unit(type))
                            }
                        }
                    }

                    Section("Build Structure") {
                        ForEach(buildableBuildings(), id: \.self) { b in
                            buildButton(label: b.displayName,
                                        cost: b.cost,
                                        item: .building(b),
                                        detail: b.blurb,
                                        built: city.buildings.contains(b))
                        }
                    }

                    Section("World Wonders") {
                        ForEach(buildableWonders(city), id: \.self) { w in
                            buildButton(label: "✨ \(w.displayName)",
                                        cost: w.cost,
                                        item: .wonder(w),
                                        detail: w.blurb,
                                        built: city.wonders.contains(w))
                        }
                    }
                }
                .navigationTitle(city.name)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            } else {
                Text("City no longer exists").onAppear { dismiss() }
            }
        }
    }

    private func buildableUnits(naval: Bool) -> [UnitType] {
        let techs = game.player(game.humanPlayer).tech.researched
        return UnitType.allCases.filter { type in
            guard type.isNaval == naval else { return false }
            guard let req = type.requiredTech else { return true }
            return techs.contains(req)
        }
    }

    private func buildableWonders(_ city: City) -> [WonderType] {
        let techs = game.player(game.humanPlayer).tech.researched
        return WonderType.allCases.filter { w in
            // Hide wonders built elsewhere (unless this city already has it, to show the ✓).
            if game.builtWonders.contains(w) && !city.wonders.contains(w) { return false }
            if w.requiresCoast && !city.isCoastal { return false }
            return w.requiredTech.map { techs.contains($0) } ?? true
        }
    }

    private func buildableBuildings() -> [BuildingType] {
        let techs = game.player(game.humanPlayer).tech.researched
        return BuildingType.allCases.filter { b in
            guard let req = b.requiredTech else { return true }
            return techs.contains(req)
        }
    }

    @ViewBuilder
    private func buildButton(label: String, cost: Int, item: ProductionItem,
                             detail: String? = nil, built: Bool = false) -> some View {
        Button {
            game.setProduction(item, cityID: cityID)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).foregroundColor(built ? .secondary : .primary)
                    if let d = detail { Text(d).font(.caption2).foregroundColor(.secondary) }
                }
                Spacer()
                if built {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                } else if city?.queue == item {
                    Image(systemName: "hammer.fill").foregroundColor(.orange)
                } else {
                    Text("\(cost) ⚒").foregroundColor(.secondary)
                }
            }
        }
        .disabled(built)
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack { Text(k); Spacer(); Text(v).foregroundColor(.secondary) }
    }
}
