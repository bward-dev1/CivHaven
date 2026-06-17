import Foundation

/// Dijkstra over hex tiles respecting per-tile movement cost.
enum Pathfinder {
    /// Returns the cheapest path (excluding `start`, including `goal`) or nil.
    static func path(from start: HexCoord, to goal: HexCoord, map: GameMap,
                     blocked: Set<HexCoord> = []) -> [HexCoord]? {
        guard map.contains(goal), map[goal]?.moveCost != nil || goal == start else { return nil }

        var frontier = PriorityQueue()
        frontier.push(start, priority: 0)
        var cameFrom: [HexCoord: HexCoord] = [:]
        var costSoFar: [HexCoord: Int] = [start: 0]

        while let current = frontier.pop() {
            if current == goal { break }
            for next in current.neighbors {
                guard let tile = map[next], let stepCost = tile.moveCost else { continue }
                if blocked.contains(next) && next != goal { continue }
                let newCost = (costSoFar[current] ?? 0) + stepCost
                if costSoFar[next] == nil || newCost < costSoFar[next]! {
                    costSoFar[next] = newCost
                    frontier.push(next, priority: newCost)
                    cameFrom[next] = current
                }
            }
        }

        guard cameFrom[goal] != nil || start == goal else { return nil }
        var path: [HexCoord] = []
        var node = goal
        while node != start {
            path.append(node)
            guard let prev = cameFrom[node] else { return nil }
            node = prev
        }
        return path.reversed()
    }

    /// All tiles reachable from `start` within `budget` movement points.
    static func reachable(from start: HexCoord, budget: Int, map: GameMap,
                          blocked: Set<HexCoord> = []) -> [HexCoord: Int] {
        var costSoFar: [HexCoord: Int] = [start: 0]
        var frontier = PriorityQueue()
        frontier.push(start, priority: 0)

        while let current = frontier.pop() {
            for next in current.neighbors {
                guard let tile = map[next], let stepCost = tile.moveCost else { continue }
                if blocked.contains(next) { continue }
                let newCost = (costSoFar[current] ?? 0) + stepCost
                if newCost <= budget && (costSoFar[next] == nil || newCost < costSoFar[next]!) {
                    costSoFar[next] = newCost
                    frontier.push(next, priority: newCost)
                }
            }
        }
        costSoFar.removeValue(forKey: start)
        return costSoFar
    }
}

/// Minimal binary-heap priority queue keyed by Int priority.
private struct PriorityQueue {
    private var heap: [(coord: HexCoord, priority: Int)] = []

    mutating func push(_ coord: HexCoord, priority: Int) {
        heap.append((coord, priority))
        siftUp(heap.count - 1)
    }

    mutating func pop() -> HexCoord? {
        guard !heap.isEmpty else { return nil }
        heap.swapAt(0, heap.count - 1)
        let item = heap.removeLast()
        if !heap.isEmpty { siftDown(0) }
        return item.coord
    }

    private mutating func siftUp(_ i: Int) {
        var child = i
        while child > 0 {
            let parent = (child - 1) / 2
            if heap[child].priority < heap[parent].priority {
                heap.swapAt(child, parent)
                child = parent
            } else { break }
        }
    }

    private mutating func siftDown(_ i: Int) {
        var parent = i
        let n = heap.count
        while true {
            let l = 2 * parent + 1
            let r = 2 * parent + 2
            var smallest = parent
            if l < n && heap[l].priority < heap[smallest].priority { smallest = l }
            if r < n && heap[r].priority < heap[smallest].priority { smallest = r }
            if smallest == parent { break }
            heap.swapAt(parent, smallest)
            parent = smallest
        }
    }
}
