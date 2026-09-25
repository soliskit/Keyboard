import SwiftUI
import GameController

/// The keys this test app watches for.
enum TestKey: String, CaseIterable, Identifiable {
    case w, a, s, d
    case h, p, c
    case space, returnKey

    var id: String { rawValue }

    var label: String {
        switch self {
        case .space: return "Space"
        case .returnKey: return "Return"
        default: return rawValue.uppercased()
        }
    }

    var symbol: String? {
        switch self {
        case .space: return "space"
        case .returnKey: return "return"
        default: return nil
        }
    }

    /// Maps a GameController key code to a test key.
    init?(keyCode: GCKeyCode) {
        switch keyCode {
        case .keyW: self = .w
        case .keyA: self = .a
        case .keyS: self = .s
        case .keyD: self = .d
        case .keyH: self = .h
        case .keyP: self = .p
        case .keyC: self = .c
        case .spacebar: self = .space
        case .returnOrEnter, .keypadEnter: self = .returnKey
        default: return nil
        }
    }

    /// Maps a UIKit hardware key usage code to a test key.
    init?(hidUsage: UIKeyboardHIDUsage) {
        switch hidUsage {
        case .keyboardW: self = .w
        case .keyboardA: self = .a
        case .keyboardS: self = .s
        case .keyboardD: self = .d
        case .keyboardH: self = .h
        case .keyboardP: self = .p
        case .keyboardC: self = .c
        case .keyboardSpacebar: self = .space
        case .keyboardReturnOrEnter, .keypadEnter: self = .returnKey
        default: return nil
        }
    }

    /// Maps a SwiftUI key press to a test key.
    init?(press: KeyPress) {
        if press.key == .space {
            self = .space
            return
        }
        if press.key == .return {
            self = .returnKey
            return
        }
        switch press.characters.lowercased() {
        case "w": self = .w
        case "a": self = .a
        case "s": self = .s
        case "d": self = .d
        case "h": self = .h
        case "p": self = .p
        case "c": self = .c
        case " ": self = .space
        case "\r", "\n": self = .returnKey
        default: return nil
        }
    }
}

/// Which API reported an event.
enum InputSource: String {
    case gameController = "GameController"
    case swiftUI = "SwiftUI"
    case uiKit = "UIKit"

    var shortName: String {
        switch self {
        case .gameController: return "GC"
        case .swiftUI: return "UI"
        case .uiKit: return "UK"
        }
    }
}

struct KeyState {
    var gameControllerDown = false
    var swiftUIDown = false
    var uiKitDown = false
    var gameControllerCount = 0
    var swiftUICount = 0
    var uiKitCount = 0

    var isDown: Bool { gameControllerDown || swiftUIDown || uiKitDown }
    var maxCount: Int { max(gameControllerCount, swiftUICount, uiKitCount) }
}

struct LogEntry: Identifiable {
    let id = UUID()
    let date = Date()
    let source: InputSource?
    let text: String
}

/// Tracks keyboard connection state and key presses from three independent sources:
/// the GameController framework (GCKeyboard), SwiftUI's onKeyPress and UIKit's
/// pressesBegan/pressesEnded on a first responder view.
/// Comparing both shows which input path works inside Swift Playgrounds on iPadOS.
@MainActor
@Observable
final class KeyboardMonitor {
    private(set) var isKeyboardConnected = false
    private(set) var keyboardName: String?
    private(set) var states: [TestKey: KeyState] = [:]
    private(set) var log: [LogEntry] = []

    private let maxLogEntries = 50

    func state(for key: TestKey) -> KeyState {
        states[key] ?? KeyState()
    }

    /// Checks for a keyboard that was already connected before the app launched.
    func start() {
        if let keyboard = GCKeyboard.coalesced {
            keyboardDidConnect(keyboard)
        } else {
            addLog("No hardware keyboard detected yet", source: .gameController)
        }
    }

    func keyboardDidConnect(_ keyboard: GCKeyboard) {
        let wasConnected = isKeyboardConnected
        isKeyboardConnected = true
        keyboardName = keyboard.vendorName
        if !wasConnected {
            addLog("Keyboard connected: \(keyboard.vendorName ?? "Unknown")", source: .gameController)
        }
        attachHandler()
    }

    func keyboardDidDisconnect() {
        // Another keyboard may still be attached, so ask for the coalesced keyboard again.
        if let keyboard = GCKeyboard.coalesced {
            keyboardName = keyboard.vendorName
            return
        }
        isKeyboardConnected = false
        keyboardName = nil
        for key in TestKey.allCases {
            states[key, default: KeyState()].gameControllerDown = false
        }
        addLog("Keyboard disconnected", source: .gameController)
    }

    private func attachHandler() {
        // GCKeyboard.coalesced combines every connected keyboard into one device.
        // The handler runs on the main queue by default.
        GCKeyboard.coalesced?.keyboardInput?.keyChangedHandler = { [weak self] _, _, keyCode, pressed in
            MainActor.assumeIsolated {
                self?.handleGameController(keyCode: keyCode, pressed: pressed)
            }
        }
    }

    private func handleGameController(keyCode: GCKeyCode, pressed: Bool) {
        // A key event also proves a keyboard is attached, even if the connect notification was missed.
        if !isKeyboardConnected, let keyboard = GCKeyboard.coalesced {
            keyboardDidConnect(keyboard)
        }
        guard let key = TestKey(keyCode: keyCode) else {
            if pressed {
                addLog("Other key (code \(keyCode.rawValue)) pressed", source: .gameController)
            }
            return
        }
        var state = self.state(for: key)
        if pressed && !state.gameControllerDown {
            state.gameControllerCount += 1
        }
        state.gameControllerDown = pressed
        states[key] = state
        addLog("\(key.label) \(pressed ? "down" : "up")", source: .gameController)
    }

    /// Handles a SwiftUI key press. Returns true when the key is one of the test keys.
    func handleSwiftUI(_ press: KeyPress) -> Bool {
        guard let key = TestKey(press: press) else {
            if press.phase == .down {
                addLog("Other key \"\(press.characters)\" pressed", source: .swiftUI)
            }
            return false
        }
        var state = self.state(for: key)
        switch press.phase {
        case .down:
            state.swiftUICount += 1
            state.swiftUIDown = true
            addLog("\(key.label) down", source: .swiftUI)
        case .up:
            state.swiftUIDown = false
            addLog("\(key.label) up", source: .swiftUI)
        default:
            // Key repeat while held; keep the key lit without logging every repeat.
            state.swiftUIDown = true
        }
        states[key] = state
        return true
    }

    /// Handles a UIKit hardware key press or release.
    func handleUIKit(usage: UIKeyboardHIDUsage, characters: String, pressed: Bool) {
        guard let key = TestKey(hidUsage: usage) else {
            if pressed {
                addLog("Other key \"\(characters)\" (usage \(usage.rawValue)) pressed", source: .uiKit)
            }
            return
        }
        var state = self.state(for: key)
        if pressed && !state.uiKitDown {
            state.uiKitCount += 1
        }
        state.uiKitDown = pressed
        states[key] = state
        addLog("\(key.label) \(pressed ? "down" : "up")", source: .uiKit)
    }

    func logFocusChange(_ source: InputSource, active: Bool) {
        let what = source == .uiKit ? "first responder" : "focus"
        addLog("\(source.rawValue) \(what) \(active ? "gained" : "lost")", source: source)
    }

    func reset() {
        states = [:]
        log = []
        addLog("Counters reset", source: nil)
    }

    private func addLog(_ text: String, source: InputSource?) {
        log.insert(LogEntry(source: source, text: text), at: 0)
        if log.count > maxLogEntries {
            log.removeLast(log.count - maxLogEntries)
        }
    }
}
