/// The typed text, kept valid at all times.
///
/// Every change goes through this type, so the text can never be longer than
/// `maxLength` and never contains control characters such as newlines or tabs,
/// whichever input the text came from.
struct TextBuffer: Equatable {
    static let maxLength = 200

    private(set) var text = ""

    var isEmpty: Bool { text.isEmpty }
    var isFull: Bool { text.count >= Self.maxLength }
    var remaining: Int { Self.maxLength - text.count }

    /// Replaces all of the text, as a text field does on every edit.
    mutating func replace(with newText: String) {
        text = Self.sanitized(newText)
    }

    /// Adds text to the end, as the onscreen keypad does.
    mutating func insert(_ newText: String) {
        text = Self.sanitized(text + newText)
    }

    /// Removes the last character. Does nothing when the text is empty.
    mutating func deleteBackward() {
        if !text.isEmpty {
            text.removeLast()
        }
    }

    mutating func clear() {
        text = ""
    }

    /// Drops control characters and cuts the text to `maxLength` characters.
    static func sanitized(_ input: String) -> String {
        let kept = input.filter { character in
            character.unicodeScalars.allSatisfy { $0.properties.generalCategory != .control }
        }
        return String(kept.prefix(maxLength))
    }
}
