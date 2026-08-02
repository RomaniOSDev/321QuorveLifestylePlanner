import SwiftUI
import UIKit

enum KeyboardDismiss {
    static func resign() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

extension View {
    /// Dismisses the keyboard on tap without blocking buttons/scrolling.
    func dismissKeyboardOnTap() -> some View {
        simultaneousGesture(
            TapGesture().onEnded {
                KeyboardDismiss.resign()
            }
        )
    }
}
