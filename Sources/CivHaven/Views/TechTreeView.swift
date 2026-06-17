import SwiftUI

/// Pick the current research from available techs; shows researched + locked.
struct TechTreeView: View {
    @ObservedObject var game: GameState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let me = game.player(game.humanPlayer)
        NavigationStack {
            List {
                if let cur = me.tech.current {
                    Section("Researching") {
                        HStack {
                            Text(cur.displayName).bold()
                            Spacer()
                            Text("\(me.tech.progress)/\(cur.cost)").foregroundColor(.secondary)
                        }
                    }
                }

                Section("Available") {
                    ForEach(me.tech.available, id: \.self) { tech in
                        Button {
                            game.setResearch(tech, player: game.humanPlayer)
                            dismiss()
                        } label: {
                            techRow(tech, state: .available)
                        }
                    }
                    if me.tech.available.isEmpty {
                        Text("All current techs researched").foregroundColor(.secondary)
                    }
                }

                Section("Researched") {
                    ForEach(Array(me.tech.researched).sorted(by: { $0.cost < $1.cost }), id: \.self) { tech in
                        techRow(tech, state: .done)
                    }
                }

                Section("Locked") {
                    ForEach(lockedTechs(me), id: \.self) { tech in
                        techRow(tech, state: .locked)
                    }
                }
            }
            .navigationTitle("Technology")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private enum RowState { case available, done, locked }

    private func lockedTechs(_ me: Player) -> [TechID] {
        TechID.allCases.filter { !me.tech.researched.contains($0) && !me.tech.canResearch($0) }
    }

    private func techRow(_ tech: TechID, state: RowState) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(tech.displayName)
                    .foregroundColor(state == .locked ? .secondary : .primary)
                Text(tech.blurb).font(.caption2).foregroundColor(.secondary)
                if !tech.prerequisites.isEmpty {
                    Text("Needs: " + tech.prerequisites.map { $0.displayName }.joined(separator: ", "))
                        .font(.caption2).foregroundColor(.orange.opacity(0.8))
                }
            }
            Spacer()
            switch state {
            case .available: Text("\(tech.cost) 🔬").foregroundColor(.cyan)
            case .done:      Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            case .locked:    Image(systemName: "lock.fill").foregroundColor(.secondary)
            }
        }
    }
}
