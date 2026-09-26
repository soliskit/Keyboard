import SwiftUI

struct ContentView: View {
    @State private var typedText = ""
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("v5: onscreen keyboard test")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("Tap here and start typing", text: $typedText)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($isFieldFocused)

            Button("Show Keyboard") {
                isFieldFocused = true
            }
            .buttonStyle(.borderedProminent)

            Text(typedText.isEmpty ? "Nothing typed yet" : typedText)
                .font(.body.monospaced())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

            KeyboardHelp()

            Spacer()
        }
        .padding()
        .onAppear {
            // Ask for the keyboard as soon as the view shows, in case the
            // Playgrounds window does not become key on its own.
            isFieldFocused = true
        }
    }
}

/// Steps for when typing does not work. Apps run inside Swift Playgrounds on iPad
/// have a known bug where a text field ignores an external keyboard, while the
/// onscreen keyboard works once the external keyboard is detached.
private struct KeyboardHelp: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Keyboard not working?")
                .font(.headline)
            Text("Swift Playgrounds apps on iPad don't receive typing from an external keyboard such as the Magic Keyboard. Detach it and use the onscreen keyboard.")
            Text("If the onscreen keyboard still doesn't appear:")
            Text("1. Tap the small keyboard icon near the bottom right corner, if there is one.")
            Text("2. Quit Swift Playgrounds from the app switcher and reopen it with the keyboard detached.")
            Text("3. In Settings > Bluetooth, make sure no keyboard is connected.")
            Text("4. Restart the iPad.")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
