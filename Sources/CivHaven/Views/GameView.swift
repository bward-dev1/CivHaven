import SwiftUI

/// Top-level gameplay screen: map + HUD + sheets + game-over overlay.
struct GameView: View {
    @StateObject private var game: GameState
    @State private var selectedUnitID: UUID?
    @State private var selectedCityID: UUID?
    @State private var showTech = false
    @State private var showCity = false
    @State private var showLog = false
    @Environment(\.dismiss) private var dismiss

    init(config: GameConfig) {
        _game = StateObject(wrappedValue: GameState(mapWidth: config.width,
                                                    mapHeight: config.height,
                                                    aiCount: config.aiCount,
                                                    seed: config.seed))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                TopBar(game: game)
                ZStack(alignment: .topTrailing) {
                    HexMapView(game: game,
                               selectedUnitID: $selectedUnitID,
                               selectedCityID: $selectedCityID)
                    logButton
                }
                BottomBar(game: game,
                          selectedUnitID: $selectedUnitID,
                          selectedCityID: $selectedCityID,
                          showTech: $showTech,
                          showCity: $showCity)
            }

            if game.isGameOver { gameOverOverlay }
        }
        .preferredColorScheme(.dark)
        .onChange(of: selectedCityID) { newValue in
            showCity = newValue != nil
        }
        .sheet(isPresented: $showTech) { TechTreeView(game: game) }
        .sheet(isPresented: $showCity, onDismiss: { selectedCityID = nil }) {
            if let cid = selectedCityID { CityView(game: game, cityID: cid) }
        }
        .sheet(isPresented: $showLog) {
            LogView(game: game)
        }
    }

    private var logButton: some View {
        HStack(spacing: 8) {
            Button { showLog = true } label: {
                Image(systemName: "list.bullet.rectangle")
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())
            }
            Button { dismiss() } label: {
                Image(systemName: "house.fill")
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .foregroundColor(.white)
        .padding(10)
    }

    private var gameOverOverlay: some View {
        VStack(spacing: 16) {
            Text(game.winner?.isHuman == true ? "🏆 Victory!" : "Game Over")
                .font(.largeTitle).bold()
            if let w = game.winner {
                Text("\(w.name) rules the world.")
            }
            Text("Survived \(game.turn) turns").foregroundColor(.secondary)
            Button("Main Menu") { dismiss() }
                .buttonStyle(.borderedProminent).tint(.blue)
        }
        .padding(40)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .foregroundColor(.white)
    }
}

/// Scrolling event log.
struct LogView: View {
    @ObservedObject var game: GameState
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List(Array(game.log.enumerated()), id: \.offset) { _, line in
                Text(line).font(.callout)
            }
            .navigationTitle("Event Log")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
