import SwiftUI

struct ContentView: View {
    @State private var typedText = ""

    var body: some View {
        VStack(spacing: 20) {
            TextField("Tap here and start typing", text: $typedText)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            Text(typedText.isEmpty ? "Nothing typed yet" : typedText)
                .font(.body.monospaced())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

            Spacer()
        }
        .padding()
    }
}
