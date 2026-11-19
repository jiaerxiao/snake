import AppKit
import SwiftUI
import SnakeCore

final class GameModel: ObservableObject {
    @Published private(set) var engine = GameEngine()
    @Published var difficulty: Difficulty {
        didSet { UserDefaults.standard.set(difficulty.rawValue, forKey: "difficulty") }
    }
    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }
    @Published private(set) var best: Int
    let scene = SnakeScene()
    private var elapsed = 0.0
    private var keyMonitor: Any?
    private var observers: [NSObjectProtocol] = []

    init() {
        let defaults = UserDefaults.standard
        best = defaults.integer(forKey: "bestScore")
        difficulty = Difficulty(rawValue: defaults.string(forKey: "difficulty") ?? "") ?? .normal
        soundEnabled = defaults.object(forKey: "soundEnabled") as? Bool ?? true
        scene.render(engine)
        scene.onFrame = { [weak self] delta in self?.advance(delta) }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, NSApp.keyWindow != nil,
                  event.modifierFlags.intersection([.command, .control, .option]).isEmpty else { return event }
            return self.handle(event) ? nil : event
        }
        for name in [NSApplication.didResignActiveNotification, NSWindow.didResignKeyNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.pause()
            })
        }
    }
    deinit {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        observers.forEach(NotificationCenter.default.removeObserver)
    }
    var playing: Bool { engine.status == .running || engine.status == .paused }
    func primaryAction() {
        switch engine.status {
        case .ready: engine.start()
        case .running: engine.pause()
        case .paused: engine.resume()
        case .gameOver, .won: engine = GameEngine(); engine.start()
        }
        elapsed = 0
        scene.render(engine)
    }
    func restart() { engine = GameEngine(); engine.start(); elapsed = 0; scene.render(engine) }
    func pause() { engine.pause(); elapsed = 0 }
    private func advance(_ delta: Double) {
        guard engine.status == .running else { elapsed = 0; return }
        elapsed += delta
        while elapsed >= difficulty.interval && engine.status == .running {
            elapsed -= difficulty.interval
            let oldScore = engine.score
            engine.step()
            if engine.score > oldScore {
                scene.celebrateFood()
                if soundEnabled { NSSound(named: "Pop")?.play() }
            }
            if engine.score > best {
                best = engine.score
                UserDefaults.standard.set(best, forKey: "bestScore")
            }
            if engine.status == .gameOver && soundEnabled { NSSound(named: "Basso")?.play() }
            scene.render(engine)
        }
    }
    private func handle(_ event: NSEvent) -> Bool {
        let direction: Direction?
        switch event.keyCode {
        case 126, 13: direction = .up
        case 125, 1: direction = .down
        case 123, 0: direction = .left
        case 124, 2: direction = .right
        case 36, 76:
            if !event.isARepeat && engine.status != .running { primaryAction() }
            return true
        case 49:
            if !event.isARepeat { primaryAction() }
            return true
        case 53: pause(); return true
        default: return false
        }
        if let direction { engine.turn(direction) }
        return true
    }
}
