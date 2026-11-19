import SwiftUI
import SpriteKit
import SnakeCore

@main
struct SnakeMacApp: App {
    @StateObject private var game = GameModel()
    var body: some Scene {
        WindowGroup("贪吃蛇") {
            GameView(game: game)
                .frame(minWidth: 520, minHeight: 680)
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 640, height: 790)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("新游戏") { game.restart() }.keyboardShortcut("n")
            }
        }
    }
}

private struct GameView: View {
    @ObservedObject var game: GameModel
    private let accent = Color(red: 0.65, green: 0.94, blue: 0.37)
    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Circle().fill(accent).frame(width: 7, height: 7)
                        Text("CLASSIC / 01").font(.system(size: 10, weight: .semibold, design: .monospaced)).tracking(2)
                            .foregroundStyle(accent)
                    }
                    Text("贪吃蛇").font(.system(size: 29, weight: .bold))
                }
                Spacer()
                score("本局得分", value: game.engine.score, highlighted: true)
                Rectangle().fill(.white.opacity(0.1)).frame(width: 1, height: 35).padding(.horizontal, 8)
                score("最高纪录", value: game.best, highlighted: false)
            }
            HStack(spacing: 6) {
                Circle().fill(game.engine.status == .running ? accent : .gray).frame(width: 5, height: 5)
                Text(statusLabel).font(.system(size: 11, weight: .medium))
                Spacer()
                if game.playing {
                    Button { game.primaryAction() } label: {
                        Label(game.engine.status == .running ? "暂停游戏" : "继续游戏",
                              systemImage: game.engine.status == .running ? "pause.fill" : "play.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(accent)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(accent.opacity(0.1), in: Capsule())
                            .overlay(Capsule().strokeBorder(accent.opacity(0.2), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .help("空格键暂停或继续游戏")
                    .padding(.trailing, 10)
                }
                Text("24 × 24").font(.system(size: 11, design: .monospaced))
            }.foregroundStyle(.white.opacity(0.45)).frame(height: 30)

            GeometryReader { geometry in
                let side = min(geometry.size.width, geometry.size.height)
                ZStack {
                    SpriteView(scene: game.scene, preferredFramesPerSecond: 60)
                        .frame(width: side, height: side)
                        .accessibilityLabel("贪吃蛇棋盘，当前得分 \(game.engine.score)")
                    if game.engine.status != .running { overlay }
                }
                .frame(width: side, height: side)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.09), lineWidth: 1))
                .frame(width: geometry.size.width, height: geometry.size.height)
            }.aspectRatio(1, contentMode: .fit)

            HStack {
                DifficultySelector(selection: $game.difficulty, isLocked: game.playing, accent: accent)
                Spacer()
                Button { game.soundEnabled.toggle() } label: {
                    Image(systemName: game.soundEnabled ? "speaker.wave.2" : "speaker.slash")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .help(game.soundEnabled ? "关闭音效" : "开启音效")
                .accessibilityLabel(game.soundEnabled ? "关闭音效" : "开启音效")
            }.foregroundStyle(.white.opacity(0.7))
            HStack(spacing: 16) {
                Text("↑ ↓ ← → / WASD  移动")
                Text("SPACE  暂停 / 继续")
                Text("⌘ N  新游戏")
            }
            .font(.system(size: 10, design: .monospaced))
            .foregroundStyle(.white.opacity(0.35))
        }
        .padding(.horizontal, 28).padding(.top, 38).padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.047, green: 0.059, blue: 0.051))
    }
    private func score(_ label: String, value: Int, highlighted: Bool) -> some View {
        VStack(alignment: .trailing, spacing: 5) {
            Text(label).font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))
            Text(String(format: "%03d", value))
                .font(.system(size: 27, weight: .semibold, design: .monospaced))
                .foregroundStyle(highlighted ? accent : .white.opacity(0.85))
                .monospacedDigit()
        }
    }
    private var statusLabel: String {
        switch game.engine.status {
        case .ready: return "准备好，开始一局"
        case .running: return "游戏进行中"
        case .paused: return "已暂停 · 继续后再出发"
        case .gameOver: return "本局结束"
        case .won: return "棋盘已填满 · 挑战成功"
        }
    }
    private var overlay: some View {
        ZStack {
            Color.black.opacity(0.53)
            VStack(spacing: 14) {
                Image(systemName: overlayIcon)
                    .font(.system(size: 32, weight: .light)).foregroundStyle(accent)
                    .padding(.bottom, 5)
                Text(overlayTitle).font(.system(size: 28, weight: .bold))
                Text(overlaySubtitle).font(.system(size: 12)).foregroundStyle(.white.opacity(0.6))
                Button { game.primaryAction() } label: {
                    HStack(spacing: 10) {
                        Text(buttonTitle)
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.85))
                    .padding(.horizontal, 25).padding(.vertical, 13)
                    .background(accent, in: Capsule())
                }.buttonStyle(.plain).padding(.top, 10)
                Text("按回车键 \(buttonTitle)").font(.system(size: 10)).foregroundStyle(.white.opacity(0.35))
            }.padding(24)
        }
    }
    private var overlayIcon: String {
        switch game.engine.status {
        case .paused: return "pause.circle"
        case .gameOver: return "arrow.counterclockwise"
        case .won: return "trophy"
        default: return "leaf"
        }
    }
    private var overlayTitle: String {
        switch game.engine.status {
        case .paused: return "休息一下"
        case .gameOver: return "再挑战一次？"
        case .won: return "完美通关！"
        default: return "每一口，都是成长。"
        }
    }
    private var overlaySubtitle: String {
        switch game.engine.status {
        case .paused: return "准备好后，继续你的路线。"
        case .gameOver, .won: return "本局得分 \(game.engine.score)  ·  最高纪录 \(game.best)"
        default: return "吃掉食物，保持前进，小心别撞到自己。"
        }
    }
    private var buttonTitle: String {
        switch game.engine.status {
        case .paused: return "继续游戏"
        case .gameOver, .won: return "再来一局"
        default: return "开始游戏"
        }
    }
}

private extension Difficulty {
    var title: String {
        switch self {
        case .easy: return "悠闲"
        case .normal: return "经典"
        case .hard: return "极速"
        }
    }
    var symbol: String {
        switch self {
        case .easy: return "leaf.fill"
        case .normal: return "square.grid.2x2.fill"
        case .hard: return "bolt.fill"
        }
    }
    var hint: String {
        switch self {
        case .easy: return "慢慢探索，从容转弯"
        case .normal: return "熟悉的节奏，经典的挑战"
        case .hard: return "加快节奏，挑战反应"
        }
    }
}

private struct DifficultySelector: View {
    @Binding var selection: Difficulty
    let isLocked: Bool
    let accent: Color
    @Namespace private var highlight
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Difficulty.allCases, id: \.self) { difficulty in
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                        selection = difficulty
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: difficulty.symbol).font(.system(size: 10, weight: .semibold))
                        Text(difficulty.title).font(.system(size: 12, weight: .semibold))
                    }
                    .frame(width: 72, height: 32)
                    .foregroundStyle(selection == difficulty ? Color.black.opacity(0.85) : accent.opacity(0.7))
                    .background {
                        if selection == difficulty {
                            Capsule().fill(accent)
                                .matchedGeometryEffect(id: "difficulty", in: highlight)
                                .shadow(color: accent.opacity(0.16), radius: 6, y: 2)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(DifficultyButtonStyle(accent: accent, selected: selection == difficulty))
                .disabled(isLocked)
                .accessibilityLabel("\(difficulty.title)难度")
                .accessibilityAddTraits(selection == difficulty ? .isSelected : [])
                .help(isLocked ? "本局难度：\(selection.title)，结束后可切换" : difficulty.hint)
            }
        }
        .padding(4)
        .background(accent.opacity(0.045), in: Capsule())
        .overlay(Capsule().strokeBorder(accent.opacity(0.16), lineWidth: 1))
        .opacity(isLocked ? 0.65 : 1)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("游戏难度")
    }
}

private struct DifficultyButtonStyle: ButtonStyle {
    let accent: Color
    let selected: Bool
    @State private var hovering = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(accent.opacity(hovering && isEnabled && !selected ? 0.1 : 0), in: Capsule())
            .opacity(configuration.isPressed ? 0.75 : 1)
            .onHover { hovering = $0 }
    }
}
