import CoreGraphics
import Foundation

/// Axial hex coordinate (pointy-top layout). q = column axis, r = row axis.
/// Cube coordinate is derived (x = q, z = r, y = -x - z) for distance math.
struct HexCoord: Hashable, Codable {
    var q: Int
    var r: Int

    init(_ q: Int, _ r: Int) {
        self.q = q
        self.r = r
    }

    var s: Int { -q - r }

    /// The six neighbour directions in axial coordinates.
    static let directions: [HexCoord] = [
        HexCoord(1, 0), HexCoord(1, -1), HexCoord(0, -1),
        HexCoord(-1, 0), HexCoord(-1, 1), HexCoord(0, 1)
    ]

    func neighbor(_ direction: Int) -> HexCoord {
        let d = HexCoord.directions[((direction % 6) + 6) % 6]
        return HexCoord(q + d.q, r + d.r)
    }

    var neighbors: [HexCoord] {
        HexCoord.directions.map { HexCoord(q + $0.q, r + $0.r) }
    }

    /// Hex grid distance using cube coordinates.
    func distance(to other: HexCoord) -> Int {
        (abs(q - other.q) + abs(r - other.r) + abs(s - other.s)) / 2
    }

    /// All coordinates within `radius` rings (including self).
    func withinRange(_ radius: Int) -> [HexCoord] {
        var results: [HexCoord] = []
        for dq in -radius...radius {
            for dr in max(-radius, -dq - radius)...min(radius, -dq + radius) {
                results.append(HexCoord(q + dq, r + dr))
            }
        }
        return results
    }
}

/// Pure layout helper: converts between hex coordinates and screen points.
/// Pointy-top hexagons.
enum HexLayout {
    /// `size` is the hex circumradius (centre to corner) in points.
    static func pixel(for coord: HexCoord, size: CGFloat, origin: CGPoint) -> CGPoint {
        let x = size * (sqrt(3.0) * CGFloat(coord.q) + sqrt(3.0) / 2.0 * CGFloat(coord.r))
        let y = size * (3.0 / 2.0 * CGFloat(coord.r))
        return CGPoint(x: x + origin.x, y: y + origin.y)
    }

    /// Inverse: which hex contains the given screen point.
    static func coord(for point: CGPoint, size: CGFloat, origin: CGPoint) -> HexCoord {
        let px = point.x - origin.x
        let py = point.y - origin.y
        let q = (sqrt(3.0) / 3.0 * px - 1.0 / 3.0 * py) / size
        let r = (2.0 / 3.0 * py) / size
        return roundToHex(q: q, r: r)
    }

    /// Six corner points of a pointy-top hex centred at `center`.
    static func corners(center: CGPoint, size: CGFloat) -> [CGPoint] {
        (0..<6).map { i -> CGPoint in
            let angle = CGFloat.pi / 180.0 * (60.0 * CGFloat(i) - 30.0)
            return CGPoint(x: center.x + size * cos(angle),
                           y: center.y + size * sin(angle))
        }
    }

    private static func roundToHex(q: CGFloat, r: CGFloat) -> HexCoord {
        let s = -q - r
        var rq = (q).rounded()
        var rr = (r).rounded()
        let rs = (s).rounded()
        let dq = abs(rq - q)
        let dr = abs(rr - r)
        let ds = abs(rs - s)
        if dq > dr && dq > ds {
            rq = -rr - rs
        } else if dr > ds {
            rr = -rq - rs
        }
        return HexCoord(Int(rq), Int(rr))
    }
}
