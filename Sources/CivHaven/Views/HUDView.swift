import SwiftUI

/// Top status bar: turn, player, gold, science, research.
struct TopBar: View {
    @ObservedObject var game: GameState

    var body: some View {
        let me = game.player(game.humanPlayer)
        HStack(spacing: 14) {
            Label("\(game.turn)", systemImage: "clock")
            Label("\(me.gold)", systemImage: "dollarsign.circle").foregroundColor(.yellow)
            Label("\(sciencePerTurn)/t", systemImage: "flask").foregroundColor(.cyan)
            Spacer()
            if let cur = me.tech.current {
                VStack(alignment: .trailing, spacing: 1) {
                    Text(cur.displayName).font(.caption).bold()
                    ProgressView(value: Double(me.tech.progress), total: Double(cur.cost))
                        .frame(width: 90)
                        .tint(.cyan)
                }
            } else {
                Text("No research").font(.caption).foregroundColor(.orange)
            }
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private var sciencePerTurn: Int {
        var s = 3
        for c in game.cities(ofPlayer: game.humanPlayer) {
            s += c.population
            if c.buildings.contains(.library) { s += 2 }
        }
        return s
    }
}

/// Bottom action bar — context depends on what is selected.
struct BottomBar: View {
    @ObservedObject var game: GameState
    @Binding var selectedUnitID: UUID?
    @Binding var selectedCityID: UUID?
    @Binding var showTech: Bool
    @Binding var showCity: Bool

    var body: some View {
        HStack(spacing: 10) {
            if let uid = selectedUnitID, let unit = game.units.first(where: { $0.id == uid }) {
                unitActions(unit)
            } else {
                Text("Tap a unit or city").foregroundColor(.white.opacity(0.7)).font(.subheadline)
            }
            Spacer()
            Button { showTech = true } label: {
                Image(systemName: "flask.fill"); Text("Tech")
            }.buttonStyle(.bordered).tint(.cyan)

            Button {
                selectedUnitID = nil; selectedCityID = nil
                game.endTurn()
            } label: {
                Text("End Turn").bold().frame(minWidth: 90)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(game.isGameOver)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private func unitActions(_ unit: Unit) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                Text("\(unit.type.symbol) \(unit.type.rawValue.capitalized)").font(.subheadline).bold()
                Text("Moves \(unit.movesLeft)/\(unit.type.maxMovement) · HP \(unit.hp)")
                    .font(.caption2).foregroundColor(.white.opacity(0.7))
            }
            if unit.type == .settler {
                Button("Found City") { game.foundCity(with: unit.id); selectedUnitID = nil }
                    .buttonStyle(.bordered).tint(.green)
                    .disabled(game.map[unit.coord]?.isSettleable != true)
            }
            if unit.type.isCombatant {
                Button("Fortify") { game.fortify(unit.id) }
                    .buttonStyle(.bordered).tint(.orange)
            }
        }
        .foregroundColor(.white)
    }
}
