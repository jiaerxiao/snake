import SpriteKit
import SnakeCore

final class SnakeScene: SKScene {
    var onFrame: ((TimeInterval) -> Void)?
    private var lastTime: TimeInterval?
    private let pieces = SKNode()
    private let grid = SKShapeNode()
    private let unit: CGFloat = 24
    private let inset: CGFloat = 12
    private let green = NSColor(calibratedRed: 0.65, green: 0.94, blue: 0.37, alpha: 1)

    override init() {
        super.init(size: CGSize(width: 600, height: 600))
        scaleMode = .aspectFit
        backgroundColor = NSColor(calibratedRed: 0.075, green: 0.10, blue: 0.085, alpha: 1)
        let path = CGMutablePath()
        for index in 0...24 {
            let p = inset + CGFloat(index) * unit
            path.move(to: CGPoint(x: inset, y: p))
            path.addLine(to: CGPoint(x: 588, y: p))
            path.move(to: CGPoint(x: p, y: inset))
            path.addLine(to: CGPoint(x: p, y: 588))
        }
        grid.path = path
        grid.strokeColor = NSColor.white.withAlphaComponent(0.045)
        grid.lineWidth = 0.7
        addChild(grid)
        addChild(pieces)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func update(_ currentTime: TimeInterval) {
        let delta = lastTime.map { min(currentTime - $0, 0.1) } ?? 0
        lastTime = currentTime
        onFrame?(delta)
    }
    private func position(_ cell: Cell) -> CGPoint {
        CGPoint(x: inset + (CGFloat(cell.x) + 0.5) * unit,
                y: inset + (23.5 - CGFloat(cell.y)) * unit)
    }
    func render(_ game: GameEngine) {
        pieces.removeAllChildren()
        if let food = game.food {
            let glow = SKShapeNode(circleOfRadius: 13)
            glow.fillColor = NSColor.systemOrange.withAlphaComponent(0.12)
            glow.strokeColor = .clear
            glow.position = position(food)
            pieces.addChild(glow)
            let fruit = SKShapeNode(rectOf: CGSize(width: 14, height: 14), cornerRadius: 5)
            fruit.fillColor = NSColor(calibratedRed: 1, green: 0.48, blue: 0.29, alpha: 1)
            fruit.strokeColor = .clear
            fruit.position = position(food)
            pieces.addChild(fruit)
        }
        for (index, cell) in game.snake.enumerated() {
            let node = SKShapeNode(rectOf: CGSize(width: 21, height: 21), cornerRadius: index == 0 ? 7 : 5)
            node.position = position(cell)
            node.fillColor = green.withAlphaComponent(index == 0 ? 1 : max(0.4, 0.85 - Double(index) * 0.012))
            node.strokeColor = .clear
            pieces.addChild(node)
            if index == 0 {
                for side: CGFloat in [-1, 1] {
                    let eye = SKShapeNode(circleOfRadius: 1.9)
                    eye.fillColor = backgroundColor
                    eye.strokeColor = .clear
                    switch game.direction {
                    case .right: eye.position = CGPoint(x: 4, y: side * 4)
                    case .left: eye.position = CGPoint(x: -4, y: side * 4)
                    case .up: eye.position = CGPoint(x: side * 4, y: 4)
                    case .down: eye.position = CGPoint(x: side * 4, y: -4)
                    }
                    node.addChild(eye)
                }
            }
        }
    }
    func celebrateFood() {
        let flash = SKShapeNode(rect: CGRect(x: 2, y: 2, width: 596, height: 596), cornerRadius: 18)
        flash.strokeColor = green.withAlphaComponent(0.5)
        flash.lineWidth = 3
        flash.fillColor = .clear
        addChild(flash)
        flash.run(.sequence([.fadeOut(withDuration: 0.3), .removeFromParent()]))
    }
}
