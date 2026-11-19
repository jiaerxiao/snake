import Foundation

func XCTAssertEqual<T: Equatable>(_ a: T, _ b: T) { precondition(a == b, "Expected \(a) == \(b)") }
func XCTAssertNotNil<T>(_ a: T?) { precondition(a != nil) }
func XCTAssertNil<T>(_ a: T?) { precondition(a == nil) }
func XCTAssertFalse(_ a: Bool) { precondition(!a) }

@main
struct GameEngineTests {
    static func main() {
        let checks = GameEngineTests()
        checks.testReadyAndPausedDoNotMove()
        checks.testReverseRejectedAndQuickTurnsConsumedOnePerStep()
        checks.testEatingGrowsScoresAndRespawnsOnFreeCell()
        checks.testWallCollisionEndsGameWithoutMovingSnake()
        checks.testMovingIntoVacatingTailIsAllowed()
        checks.testBodyCollisionEndsGame()
        checks.testLastFreeCellWinsWithoutFoodRespawn()
        checks.testFoodNeverSpawnsInsideInitialSnake()
        print("Passed 8 game rule checks")
    }
    func testReadyAndPausedDoNotMove() {
        var game = GameEngine()
        let original = game.snake
        game.step()
        XCTAssertEqual(game.snake, original)
        game.start(); game.pause(); game.step()
        XCTAssertEqual(game.snake, original)
        game.resume(); game.step()
        XCTAssertEqual(game.snake[0], Cell(13, 12))
    }
    func testReverseRejectedAndQuickTurnsConsumedOnePerStep() {
        var game = GameEngine()
        game.start()
        game.turn(.left) // Direct reversal must be ignored.
        game.turn(.up)
        game.turn(.left)
        game.step()
        XCTAssertEqual(game.snake[0], Cell(12, 11))
        game.step()
        XCTAssertEqual(game.snake[0], Cell(11, 11))
    }
    func testEatingGrowsScoresAndRespawnsOnFreeCell() {
        var game = GameEngine(size: 6, snake: [Cell(2, 2), Cell(1, 2), Cell(0, 2)], direction: .right, food: Cell(3, 2))
        game.start(); game.step()
        XCTAssertEqual(game.score, 10)
        XCTAssertEqual(game.snake.count, 4)
        XCTAssertNotNil(game.food)
        XCTAssertFalse(game.snake.contains(game.food!))
    }
    func testWallCollisionEndsGameWithoutMovingSnake() {
        var game = GameEngine(size: 6, snake: [Cell(5, 2), Cell(4, 2)], direction: .right, food: Cell(0, 0))
        let original = game.snake
        game.start(); game.step()
        XCTAssertEqual(game.status, .gameOver)
        XCTAssertEqual(game.snake, original)
    }
    func testMovingIntoVacatingTailIsAllowed() {
        var game = GameEngine(size: 6, snake: [Cell(2, 2), Cell(2, 3), Cell(1, 3), Cell(1, 2)], direction: .left, food: Cell(5, 5))
        game.start(); game.step()
        XCTAssertEqual(game.status, .running)
        XCTAssertEqual(game.snake[0], Cell(1, 2))
    }
    func testBodyCollisionEndsGame() {
        var game = GameEngine(size: 6, snake: [Cell(2, 2), Cell(2, 3), Cell(1, 3), Cell(1, 2), Cell(0, 2)], direction: .left, food: Cell(5, 5))
        game.start(); game.step()
        XCTAssertEqual(game.status, .gameOver)
    }
    func testLastFreeCellWinsWithoutFoodRespawn() {
        let head = Cell(0, 0), food = Cell(1, 0)
        let rest = (0..<6).flatMap { y in (0..<6).map { Cell($0, y) } }.filter { $0 != head && $0 != food }
        var game = GameEngine(size: 6, snake: [head] + rest, direction: .right, food: food)
        game.start(); game.step()
        XCTAssertEqual(game.status, .won)
        XCTAssertEqual(game.snake.count, 36)
        XCTAssertNil(game.food)
    }
    func testFoodNeverSpawnsInsideInitialSnake() {
        for _ in 0..<50 {
            let game = GameEngine()
            XCTAssertNotNil(game.food)
            XCTAssertFalse(game.snake.contains(game.food!))
        }
    }
}
