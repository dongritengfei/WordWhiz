import SwiftUI

// MARK: - Styled TextField with visible placeholder

struct StyledTextField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    var becomeFirstResponderOnAppear: Bool = false

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.isEditable = true
        textField.isBordered = false
        textField.drawsBackground = false
        textField.backgroundColor = .clear
        textField.font = NSFont.systemFont(ofSize: 13)
        textField.textColor = NSColor(hex: "E8E8E8")

        // Use a brighter color for placeholder to ensure visibility on dark bg (#2A2A2A)
        let placeholderColor = NSColor(hex: "BBBBBB")
        textField.placeholderAttributedString = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: placeholderColor,
                .font: NSFont.systemFont(ofSize: 13)
            ]
        )

        textField.delegate = context.coordinator

        if becomeFirstResponderOnAppear {
            DispatchQueue.main.async {
                textField.becomeFirstResponder()
            }
        }
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: StyledTextField

        init(_ parent: StyledTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }
    }
}

// MARK: - Styled SecureField with visible placeholder

struct StyledSecureField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String

    func makeNSView(context: Context) -> NSSecureTextField {
        let textField = NSSecureTextField()
        textField.isEditable = true
        textField.isBordered = false
        textField.drawsBackground = false
        textField.backgroundColor = .clear
        textField.font = NSFont.systemFont(ofSize: 13)
        textField.textColor = NSColor(hex: "E8E8E8")

        let placeholderColor = NSColor(hex: "BBBBBB")
        textField.placeholderAttributedString = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: placeholderColor,
                .font: NSFont.systemFont(ofSize: 13)
            ]
        )

        textField.delegate = context.coordinator
        return textField
    }

    func updateNSView(_ nsView: NSSecureTextField, context: Context) {
        nsView.stringValue = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: StyledSecureField

        init(_ parent: StyledSecureField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }
    }
}
