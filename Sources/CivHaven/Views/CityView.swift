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

                    Section("Build Unit") {
                        ForEach(buildableUnits(), id: \.self) { type in
                            buildButton(label: "\(type.symbol) \(type.rawValue.capitalized)",
                                        cost: type.cost,
                                        item: .unit(type))
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
                }
                .navigationTitle(city.name)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            } else {
                Text("City no longer exists").onAppear { dismiss() }
            }
        }
    }

    private func buildableUnits() -> [UnitType] {
        let techs = game.player(game.humanPlayer).tech.researched
        return UnitType.allCases.filter { type in
            guard let req = type.requiredTech else { return true }
            return techs.contains(req)
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
