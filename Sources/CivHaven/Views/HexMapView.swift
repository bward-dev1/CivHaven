import SwiftUI

/// Renders the hex map with terrain, fog, cities, units, and the current selection.
/// Supports pinch-zoom and drag-pan; tap selects/moves.
struct HexMapView: View {
    @ObservedObject var game: GameState
    @Binding var selectedUnitID: UUID?
    @Binding var selectedCityID: UUID?

    @State private var zoom: CGFloat = 1.0
    @State private var baseZoom: CGFloat = 1.0
    @State private var pan: CGSize = .zero
    @State private var basePan: CGSize = .zero

    private let baseHexSize: CGFloat = 30

    private var hexSize: CGFloat { baseHexSize * zoom }

    var body: some View {
        GeometryReader { geo in
            let origin = CGPoint(x: geo.size.width / 2 + pan.width,
                                 y: geo.size.height / 2 + pan.height)
            Canvas { context, size in
                draw(in: &context, size: size, origin: origin)
            }
            .background(Color(red: 0.04, green: 0.10, blue: 0.18))
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in pan = CGSize(width: basePan.width + value.translation.width,
                                                       height: basePan.height + value.translation.height) }
                    .onEnded { _ in basePan = pan }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { scale in zoom = (baseZoom * scale).clamped(to: 0.5...2.5) }
                    .onEnded { _ in baseZoom = zoom }
            )
            .onTapGesture { location in
                handleTap(at: location, origin: origin)
            }
        }
    }

    // MARK: - Drawing

    private func draw(in context: inout GraphicsContext, size: CGSize, origin: CGPoint) {
        let centerCoord = HexLayout.coord(for: CGPoint(x: size.width/2, y: size.height/2),
                                          size: hexSize,
                                          origin: origin)
        // Only draw tiles near the viewport for performance.
        let drawRadius = Int((max(size.width, size.height) / hexSize)) + 3

        for coord in centerCoord.withinRange(drawRadius) {
            guard let tile = game.map[coord] else { continue }
            let center = HexLayout.pixel(for: coord, size: hexSize, origin: origin)
            if center.x < -hexSize || center.x > size.width + hexSize ||
                center.y < -hexSize || center.y > size.height + hexSize { continue }

            let explored = game.isVisible(coord)
            let corners = HexLayout.corners(center: center, size: hexSize - 0.5)
            var path = Path()
            path.move(to: corners[0])
            for c in corners.dropFirst() { path.addLine(to: c) }
            path.closeSubpath()

            let fill = explored ? tile.terrain.color : Color(white: 0.08)
            context.fill(path, with: .color(fill))
            context.stroke(path, with: .color(Color.black.opacity(0.25)), lineWidth: 1)

            guard explored else { continue }

            // City ownership tint border.
            if let cid = tile.ownerCityID, let owner = game.cities.first(where: { $0.id == cid })?.owner {
                context.stroke(path, with: .color(game.player(owner).color.opacity(0.5)), lineWidth: 1.5)
            }

            // Feature / resource glyphs.
            if hexSize > 18 {
                if tile.feature == .forest {
                    drawText(&context, "🌲", at: center, size: hexSize * 0.8)
                } else if tile.feature == .jungle {
                    drawText(&context, "🌴", at: center, size: hexSize * 0.8)
                }
                if let r = tile.resource {
                    drawText(&context, r.symbol, at: CGPoint(x: center.x + hexSize*0.35, y: center.y - hexSize*0.35), size: hexSize * 0.5)
                }
            }
        }

        // Movement highlights for the selected unit.
        if let uid = selectedUnitID, let unit = game.units.first(where: { $0.id == uid }), unit.owner == game.humanPlayer {
            let reach = Pathfinder.reachable(from: unit.coord, budget: unit.movesLeft, map: game.map, domain: unit.type.domain)
            for (coord, _) in reach where game.isVisible(coord) {
                let center = HexLayout.pixel(for: coord, size: hexSize, origin: origin)
                let corners = HexLayout.corners(center: center, size: hexSize - 0.5)
                var p = Path(); p.move(to: corners[0])
                for c in corners.dropFirst() { p.addLine(to: c) }
                p.closeSubpath()
                context.fill(p, with: .color(Color.white.opacity(0.18)))
            }
        }

        // Cities.
        for city in game.cities where game.isVisible(city.coord) {
            let center = HexLayout.pixel(for: city.coord, size: hexSize, origin: origin)
            let r = hexSize * 0.55
            let rect = CGRect(x: center.x - r, y: center.y - r, width: r*2, height: r*2)
            context.fill(Path(ellipseIn: rect), with: .color(game.player(city.owner).color))
            context.stroke(Path(ellipseIn: rect), with: .color(.white), lineWidth: 2)
            drawText(&context, "\(city.population)", at: center, size: hexSize * 0.6, color: .white, bold: true)
            // health bar if damaged
            if city.hp < city.maxHP {
                drawHealthBar(&context, center: CGPoint(x: center.x, y: center.y - r - 6), width: r*2, frac: Double(city.hp)/Double(city.maxHP))
            }
        }

        // Units.
        for unit in game.units where game.isVisible(unit.coord) {
            let center = HexLayout.pixel(for: unit.coord, size: hexSize, origin: origin)
            let r = hexSize * 0.42
            let rect = CGRect(x: center.x - r, y: center.y - r, width: r*2, height: r*2)
            let isSel = unit.id == selectedUnitID
            context.fill(Path(ellipseIn: rect), with: .color(game.player(unit.owner).color.opacity(0.9)))
            context.stroke(Path(ellipseIn: rect),
                           with: .color(isSel ? .yellow : .white),
                           lineWidth: isSel ? 3 : 1.5)
            drawText(&context, unit.type.symbol, at: center, size: hexSize * 0.55)
            if unit.hp < unit.type.maxHP {
                drawHealthBar(&context, center: CGPoint(x: center.x, y: center.y - r - 5), width: r*2, frac: Double(unit.hp)/100.0)
            }
            if unit.fortified {
                drawText(&context, "🛡️", at: CGPoint(x: center.x + r*0.7, y: center.y + r*0.7), size: hexSize*0.35)
            }
        }
    }

    private func drawText(_ context: inout GraphicsContext, _ string: String, at point: CGPoint,
                          size: CGFloat, color: Color = .white, bold: Bool = false) {
        let text = Text(string).font(.system(size: size, weight: bold ? .bold : .regular)).foregroundColor(color)
        context.draw(text, at: point, anchor: .center)
    }

    private func drawHealthBar(_ context: inout GraphicsContext, center: CGPoint, width: CGFloat, frac: Double) {
        let h: CGFloat = 4
        let bg = CGRect(x: center.x - width/2, y: center.y, width: width, height: h)
        context.fill(Path(roundedRect: bg, cornerRadius: 2), with: .color(.black.opacity(0.6)))
        let fg = CGRect(x: center.x - width/2, y: center.y, width: width * CGFloat(frac), height: h)
        let color: Color = frac > 0.5 ? .green : (frac > 0.25 ? .yellow : .red)
        context.fill(Path(roundedRect: fg, cornerRadius: 2), with: .color(color))
    }

    // MARK: - Interaction

    private func handleTap(at location: CGPoint, origin: CGPoint) {
        let coord = HexLayout.coord(for: location, size: hexSize, origin: origin)
        guard game.map.contains(coord) else { return }

        // If a friendly unit is selected and the tap is elsewhere, try to move.
        if let uid = selectedUnitID,
           let unit = game.units.first(where: { $0.id == uid }),
           unit.owner == game.humanPlayer,
           unit.coord != coord {
            game.moveUnit(uid, to: coord)
            // Keep selection if the unit still exists.
            if game.units.first(where: { $0.id == uid }) == nil { selectedUnitID = nil }
            return
        }

        // Select a friendly city.
        if let city = game.city(at: coord), city.owner == game.humanPlayer {
            selectedCityID = city.id
            selectedUnitID = nil
            return
        }

        // Select a friendly unit.
        if let unit = game.unit(at: coord), unit.owner == game.humanPlayer {
            selectedUnitID = unit.id
            selectedCityID = nil
            return
        }

        selectedUnitID = nil
        selectedCityID = nil
    }
}
