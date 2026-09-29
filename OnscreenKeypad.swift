import SwiftUI

/// A keypad made of ordinary buttons. It needs only taps, so it keeps working
/// when the system keyboard does not appear.
struct OnscreenKeypad: View {
    let isFull: Bool
    let isEmpty: Bool
    let onKey: (String) -> Void
    let onDelete: () -> Void
    let onClear: () -> Void

    private let rows = ["1234567890", "qwertyuiop", "asdfghjkl", "zxcvbnm"]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(Array(row), id: \.self) { key in
                        Button {
                            onKey(String(key))
                        } label: {
                            Text(String(key))
                                .frame(maxWidth: .infinity, minHeight: 36)
                        }
                        .disabled(isFull)
                    }
                }
            }

            HStack(spacing: 6) {
                Button(action: onClear) {
                    Text("Clear")
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .disabled(isEmpty)

                Button {
                    onKey(" ")
                } label: {
                    Text("Space")
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .disabled(isFull)
                .layoutPriority(1)

                Button(action: onDelete) {
                    Image(systemName: "delete.left")
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .disabled(isEmpty)
                .accessibilityLabel("Delete")
            }
        }
        .buttonStyle(.bordered)
    }
}
