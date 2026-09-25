import SwiftUI
import GameController

struct ContentView: View {
    @State private var monitor = KeyboardMonitor()
    @FocusState private var isFocused: Bool
    @State private var isUIKitResponder = false
    @State private var uiKitFocusRequest = 0
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ConnectionCard(
                    monitor: monitor,
                    isFocused: isFocused,
                    isUIKitResponder: isUIKitResponder,
                    onRequestFocus: { isFocused = true },
                    onRequestUIKit: { uiKitFocusRequest += 1 }
                )

                KeyGroup(title: "Movement") {
                    VStack(spacing: 10) {
                        KeyTile(key: .w, state: monitor.state(for: .w))
                            .frame(maxWidth: 220)
                        HStack(spacing: 10) {
                            KeyTile(key: .a, state: monitor.state(for: .a))
                            KeyTile(key: .s, state: monitor.state(for: .s))
                            KeyTile(key: .d, state: monitor.state(for: .d))
                        }
                    }
                }

                KeyGroup(title: "Actions") {
                    HStack(spacing: 10) {
                        KeyTile(key: .h, state: monitor.state(for: .h))
                        KeyTile(key: .p, state: monitor.state(for: .p))
                        KeyTile(key: .c, state: monitor.state(for: .c))
                    }
                }

                KeyGroup(title: "Special") {
                    HStack(spacing: 10) {
                        KeyTile(key: .space, state: monitor.state(for: .space))
                        KeyTile(key: .returnKey, state: monitor.state(for: .returnKey))
                            .frame(width: 180)
                    }
                }

                EventLog(entries: monitor.log) {
                    monitor.reset()
                    uiKitFocusRequest += 1
                }
            }
            .padding()
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .background {
            // UIKit key capture. It becomes first responder automatically when it appears.
            KeyCaptureView(
                focusRequest: uiKitFocusRequest,
                onKey: { usage, characters, pressed in
                    monitor.handleUIKit(usage: usage, characters: characters, pressed: pressed)
                },
                onFirstResponderChange: { active in
                    isUIKitResponder = active
                    monitor.logFocusChange(.uiKit, active: active)
                }
            )
            .frame(width: 1, height: 1)
            .allowsHitTesting(false)
        }
        .background(Color(.systemGroupedBackground))
        .contentShape(Rectangle())
        .onTapGesture { uiKitFocusRequest += 1 }
        // SwiftUI key handling only works while this view has focus. It is only requested
        // from the SwiftUI Focus pill, because taking SwiftUI focus can take first
        // responder away from the UIKit capture view.
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
        .onKeyPress(phases: .all) { press in
            monitor.handleSwiftUI(press) ? .handled : .ignored
        }
        .onAppear {
            monitor.start()
        }
        .onChange(of: isFocused) { _, focused in
            monitor.logFocusChange(.swiftUI, active: focused)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                uiKitFocusRequest += 1
                if let keyboard = GCKeyboard.coalesced {
                    monitor.keyboardDidConnect(keyboard)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .GCKeyboardDidConnect)) { note in
            if let keyboard = note.object as? GCKeyboard {
                monitor.keyboardDidConnect(keyboard)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .GCKeyboardDidDisconnect)) { _ in
            monitor.keyboardDidDisconnect()
        }
    }
}

private struct ConnectionCard: View {
    let monitor: KeyboardMonitor
    let isFocused: Bool
    let isUIKitResponder: Bool
    let onRequestFocus: () -> Void
    let onRequestUIKit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: monitor.isKeyboardConnected ? "keyboard.fill" : "keyboard")
                    .font(.system(size: 40))
                    .foregroundStyle(monitor.isKeyboardConnected ? .green : .secondary)
                    .symbolEffect(.bounce, value: monitor.isKeyboardConnected)
                VStack(alignment: .leading, spacing: 4) {
                    Text(monitor.isKeyboardConnected ? "Keyboard Connected" : "No Keyboard Detected")
                        .font(.title2.bold())
                    Text(monitor.keyboardName ?? "Attach a hardware keyboard, then press any key")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            ViewThatFits {
                HStack(spacing: 8) { pills }
                VStack(alignment: .leading, spacing: 8) { pills }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(monitor.isKeyboardConnected ? Color.green : Color.orange, lineWidth: 2)
        )
        .animation(.default, value: monitor.isKeyboardConnected)
    }

    @ViewBuilder
    private var pills: some View {
        StatusPill(
            title: "GameController",
            isOn: monitor.isKeyboardConnected,
            onText: "Connected",
            offText: "Waiting"
        )
        Button(action: onRequestUIKit) {
            StatusPill(
                title: "UIKit Responder",
                isOn: isUIKitResponder,
                onText: "Listening",
                offText: "Tap here"
            )
        }
        .buttonStyle(.plain)
        Button(action: onRequestFocus) {
            StatusPill(
                title: "SwiftUI Focus",
                isOn: isFocused,
                onText: "Listening",
                offText: "Tap here"
            )
        }
        .buttonStyle(.plain)
    }
}

private struct StatusPill: View {
    let title: String
    let isOn: Bool
    let onText: String
    let offText: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isOn ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            Text("\(title): \(isOn ? onText : offText)")
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground), in: Capsule())
    }
}

private struct KeyGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            content
                .frame(maxWidth: .infinity)
        }
    }
}

private struct KeyTile: View {
    let key: TestKey
    let state: KeyState

    private var totalCount: Int { state.maxCount }
    private var seen: Bool { totalCount > 0 }

    var body: some View {
        VStack(spacing: 6) {
            Group {
                if let symbol = key.symbol {
                    Label(key.label, systemImage: symbol)
                } else {
                    Text(key.label)
                }
            }
            .font(.system(size: key.symbol == nil ? 34 : 20, weight: .bold, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.6)

            HStack(spacing: 4) {
                SourceDot(label: "GC", isDown: state.gameControllerDown, count: state.gameControllerCount)
                SourceDot(label: "UI", isDown: state.swiftUIDown, count: state.swiftUICount)
                SourceDot(label: "UK", isDown: state.uiKitDown, count: state.uiKitCount)
            }
        }
        .foregroundStyle(state.isDown ? Color.white : Color.primary)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, minHeight: 96)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(state.isDown ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(state.isDown ? 0 : 0.15), radius: 0, y: state.isDown ? 0 : 3)
        )
        .overlay(alignment: .topTrailing) {
            if seen {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .padding(6)
            }
        }
        .scaleEffect(state.isDown ? 0.95 : 1)
        .offset(y: state.isDown ? 2 : 0)
        .animation(.spring(duration: 0.15), value: state.isDown)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(key.label), pressed \(totalCount) times")
    }
}

private struct SourceDot: View {
    let label: String
    let isDown: Bool
    let count: Int

    var body: some View {
        Text("\(label) \(count)")
            .font(.caption2.monospacedDigit().weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(isDown ? Color.green : Color.gray.opacity(count > 0 ? 0.35 : 0.15))
            )
    }
}

private struct EventLog: View {
    let entries: [LogEntry]
    let onReset: () -> Void

    private func color(for source: InputSource) -> Color {
        switch source {
        case .gameController: return .blue
        case .swiftUI: return .purple
        case .uiKit: return .orange
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("EVENT LOG")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Reset", systemImage: "arrow.counterclockwise", action: onReset)
                    .font(.caption)
            }
            VStack(alignment: .leading, spacing: 4) {
                if entries.isEmpty {
                    Text("Press a key to see events here")
                        .foregroundStyle(.secondary)
                }
                ForEach(entries) { entry in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(entry.date, format: .dateTime.hour().minute().second())
                            .foregroundStyle(.secondary)
                        if let source = entry.source {
                            Text(source.shortName)
                                .foregroundStyle(color(for: source))
                        }
                        Text(entry.text)
                    }
                    .font(.caption.monospaced())
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

            Text("GC = GameController framework (GCKeyboard). UI = SwiftUI onKeyPress. UK = UIKit pressesBegan on a first responder view. If only some sources light up, that path is the one that works in your environment.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
