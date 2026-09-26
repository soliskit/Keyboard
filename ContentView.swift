import SwiftUI

struct ContentView: View {
    @State private var text = ""

    var body: some View {
        VStack(spacing: 20) {
            // Tapping the field focuses it and brings up the keyboard.
            TextField("Tap here to type", text: $text)
                .textFieldStyle(.roundedBorder)

            Text("You typed: \(text)")
        }
        .padding()
    }
}
