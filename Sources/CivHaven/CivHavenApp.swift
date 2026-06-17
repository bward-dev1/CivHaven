import SwiftUI

struct GameConfig: Identifiable {
    var id = UUID()
    var width: Int
    var height: Int
    var aiCount: Int
    var seed: UInt64
}

@main
struct CivHavenApp: App {
    var body: some Scene {
        WindowGroup {
            MainMenuView()
        }
    }
}

/// Title screen — choose map size, opponents, and start.
struct MainMenuView: View {
    @State private var mapSize = 1          // 0 small, 1 standard, 2 large
    @State private var aiCount = 2
    @State private var seedText = ""
    @State private var startConfig: GameConfig?

    private let sizes: [(name: String, w: Int, h: Int)] = [
        ("Duel", 16, 12), ("Standard", 24, 18), ("Large", 34, 24)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(red: 0.05, green: 0.09, blue: 0.18),
                                        Color(red: 0.10, green: 0.16, blue: 0.30)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 26) {
                    VStack(spacing: 4) {
                        Text("CIV·HAVEN").font(.system(size: 44, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text("an open 4X strategy game").font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Map").font(.headline).foregroundColor(.white)
                            Picker("Map", selection: $mapSize) {
                                ForEach(0..<sizes.count, id: \.self) { i in Text(sizes[i].name).tag(i) }
                            }.pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Opponents: \(aiCount)").font(.headline).foregroundColor(.white)
                            Stepper("", value: $aiCount, in: 1...5).labelsHidden()
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Seed (optional)").font(.headline).foregroundColor(.white)
                            TextField("random", text: $seedText)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    Button {
                        startConfig = makeConfig()
                    } label: {
                        Text("New Game").font(.title2).bold().frame(maxWidth: .infinity).padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .padding(.horizontal)

                    Spacer()
                    Text("Tap a unit, tap a tile to move. Settlers found cities. End the turn to let the world breathe.")
                        .font(.caption).foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center).padding(.horizontal, 30)
                }
                .padding(.top, 50)
            }
        }
        .fullScreenCover(item: $startConfig) { config in
            GameView(config: config)
        }
    }

    private func makeConfig() -> GameConfig {
        let size = sizes[mapSize]
        let seed: UInt64
        if let s = UInt64(seedText), s != 0 {
            seed = s
        } else {
            // Derive a seed from current time without Date APIs that may be restricted.
            seed = UInt64(bitPattern: Int64(seedText.hashValue)) ^ 0x1234_5678_9ABC_DEF0 &+ UInt64(aiCount * 7919 + size.w * 31)
        }
        return GameConfig(width: size.w, height: size.h, aiCount: aiCount, seed: seed == 0 ? 42 : seed)
    }
}

extension GameConfig: Hashable {
    static func == (lhs: GameConfig, rhs: GameConfig) -> Bool {
        lhs.width == rhs.width && lhs.height == rhs.height && lhs.aiCount == rhs.aiCount && lhs.seed == rhs.seed
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(width); hasher.combine(height); hasher.combine(aiCount); hasher.combine(seed)
    }
}
