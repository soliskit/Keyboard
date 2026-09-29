import SwiftUI
import UIKit

struct ContentView: View {
    @State private var buffer = TextBuffer()
    // What the text field shows. It always ends up equal to buffer.text.
    @State private var fieldText = ""
    @State private var isSystemKeyboardShown = false

    var body: some View {
        VStack(spacing: 16) {
            // Primary input: tapping the field brings up the system keyboard.
            TextField("Tap here to type", text: $fieldText)
                .textFieldStyle(.roundedBorder)
                .onChange(of: fieldText) { _, newText in
                    // Every edit goes through TextBuffer. If it rejects part of
                    // the edit, write the valid text back so the field shows it.
                    buffer.replace(with: newText)
                    if fieldText != buffer.text {
                        fieldText = buffer.text
                    }
                }
                .onChange(of: buffer.text) { _, newText in
                    // Keep the field in step with edits made on the keypad.
                    if fieldText != newText {
                        fieldText = newText
                    }
                }

            HStack {
                Label(
                    isSystemKeyboardShown ? "System keyboard shown" : "System keyboard hidden",
                    systemImage: isSystemKeyboardShown ? "keyboard" : "keyboard.chevron.compact.down"
                )
                Spacer()
                Text("\(buffer.remaining) characters left")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            Text(buffer.isEmpty ? "Nothing typed yet" : buffer.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

            // Backup input: works with taps alone, for when the system keyboard
            // does not appear, as happens in apps run inside Swift Playgrounds.
            OnscreenKeypad(
                isFull: buffer.isFull,
                isEmpty: buffer.isEmpty,
                onKey: { buffer.insert($0) },
                onDelete: { buffer.deleteBackward() },
                onClear: { buffer.clear() }
            )

            Spacer()
        }
        .padding()
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isSystemKeyboardShown = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isSystemKeyboardShown = false
        }
    }
}
