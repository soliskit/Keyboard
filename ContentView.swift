import SwiftUI

struct ContentView: View {
    @State private var typedText = ""
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("v4 - focus test")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("Tap here and start typing", text: $typedText)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($isFieldFocused)

            Button("No keyboard? Tap to focus the field") {
                isFieldFocused = true
            }

            Text(typedText.isEmpty ? "Nothing typed yet" : typedText)
                .font(.body.monospaced())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

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
