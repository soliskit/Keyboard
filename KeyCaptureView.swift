import SwiftUI
import UIKit

/// An invisible UIKit view that becomes first responder and reports hardware key
/// presses through pressesBegan/pressesEnded. This path does not depend on SwiftUI focus.
struct KeyCaptureView: UIViewRepresentable {
    /// Change this value to ask the view to become first responder again.
    var focusRequest: Int
    var onKey: (UIKeyboardHIDUsage, String, Bool) -> Void
    var onFirstResponderChange: (Bool) -> Void

    func makeUIView(context: Context) -> KeyCaptureUIView {
        let view = KeyCaptureUIView()
        view.onKey = onKey
        view.onFirstResponderChange = onFirstResponderChange
        return view
    }

    func updateUIView(_ view: KeyCaptureUIView, context: Context) {
        view.onKey = onKey
        view.onFirstResponderChange = onFirstResponderChange
        if view.lastFocusRequest != focusRequest {
            view.lastFocusRequest = focusRequest
            view.requestFirstResponder()
        }
    }
}

final class KeyCaptureUIView: UIView {
    var onKey: ((UIKeyboardHIDUsage, String, Bool) -> Void)?
    var onFirstResponderChange: ((Bool) -> Void)?
    var lastFocusRequest = 0

    override var canBecomeFirstResponder: Bool { true }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            requestFirstResponder()
        }
    }

    func requestFirstResponder() {
        // Defer so the request happens after the window finishes setting up.
        DispatchQueue.main.async { [weak self] in
            guard let self, self.window != nil, !self.isFirstResponder else { return }
            self.becomeFirstResponder()
        }
    }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            onFirstResponderChange?(true)
        }
        return result
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result {
            onFirstResponderChange?(false)
        }
        return result
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        report(presses, pressed: true)
        // Pass the event on so SwiftUI and the rest of the responder chain still see it.
        super.pressesBegan(presses, with: event)
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        report(presses, pressed: false)
        super.pressesEnded(presses, with: event)
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        report(presses, pressed: false)
        super.pressesCancelled(presses, with: event)
    }

    private func report(_ presses: Set<UIPress>, pressed: Bool) {
        for press in presses {
            guard let key = press.key else { continue }
            onKey?(key.keyCode, key.charactersIgnoringModifiers, pressed)
        }
    }
}
