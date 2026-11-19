public struct Cell: Hashable {
    public let x: Int
    public let y: Int
    public init(_ x: Int, _ y: Int) { self.x = x; self.y = y }
}

public enum Direction: Equatable {
    case up, down, left, right
    var offset: (Int, Int) {
        switch self {
        case .up: return (0, -1)
        case .down: return (0, 1)
        case .left: return (-1, 0)
        case .right: return (1, 0)
        }
    }
    var opposite: Direction {
        switch self {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        }
    }
}

public enum GameStatus { case ready, running, paused, gameOver, won }
public enum Difficulty: String, CaseIterable {
    case easy = "轻松", normal = "标准", hard = "挑战"
    public var interval: Double {
        switch self { case .easy: return 0.19; case .normal: return 0.13; case .hard: return 0.085 }
    }
}

public struct GameEngine {
    public let size: Int
    public private(set) var snake: [Cell]
    public private(set) var direction: Direction = .right
    public private(set) var food: Cell?
    public private(set) var score = 0
    public private(set) var status: GameStatus = .ready
    private var turns: [Direction] = []

    public init(size: Int = 24) {
        precondition(size >= 6)
        self.size = size
        let mid = size / 2
        snake = [Cell(mid, mid), Cell(mid - 1, mid), Cell(mid - 2, mid)]
        spawnFood()
    }
    // Internal state initializer supports deterministic rule checks.
    init(size: Int, snake: [Cell], direction: Direction, food: Cell?) {
        self.size = size
        self.snake = snake
        self.direction = direction
        self.food = food
    }
    public mutating func start() { if status == .ready { status = .running } }
    public mutating func pause() { if status == .running { status = .paused } }
    public mutating func resume() { if status == .paused { status = .running } }
    public mutating func turn(_ next: Direction) {
        guard status == .running, turns.count < 2 else { return }
        let previous = turns.last ?? direction
        guard next != previous, next != previous.opposite else { return }
        turns.append(next)
    }
    public mutating func step() {
        guard status == .running else { return }
        if !turns.isEmpty { direction = turns.removeFirst() }
        let delta = direction.offset
        let head = Cell(snake[0].x + delta.0, snake[0].y + delta.1)
        let growing = head == food
        let occupied = growing ? snake : Array(snake.dropLast())
        guard head.x >= 0, head.y >= 0, head.x < size, head.y < size,
              !occupied.contains(head) else { status = .gameOver; return }
        snake.insert(head, at: 0)
        if growing {
            score += 10
            if snake.count == size * size { food = nil; status = .won }
            else { spawnFood() }
        } else { snake.removeLast() }
    }
    private mutating func spawnFood() {
        let occupied = Set(snake)
        var free: [Cell] = []
        for y in 0..<size { for x in 0..<size {
            let cell = Cell(x, y)
            if !occupied.contains(cell) { free.append(cell) }
        } }
        food = free.randomElement()
    }
}
