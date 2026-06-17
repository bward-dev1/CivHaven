import SwiftUI

struct Player: Codable, Identifiable {
    let id: Int
    var name: String
    var isHuman: Bool
    var colorHex: String
    var civID: String = "rome"
    var gold: Int = 0
    var science: Int = 0
    var tech: TechState = TechState()
    var defeated: Bool = false

    var color: Color { Color(hex: colorHex) }
    var civ: Civilization { Civilization.by(id: civID) ?? Civilization.all[0] }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
