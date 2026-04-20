import SwiftUI

struct PromptEditorView: View {
    let prompt: CustomPrompt?
    let isNewPrompt: Bool
    let onSave: (String, String) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var template: String = ""
    @FocusState private var focusedField: Field?

    private enum Field {
        case name, template
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        template.contains("{{text}}") &&
        !template.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isNewPrompt ? "添加新指令" : "编辑指令")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(BrandColors.textPrimary)

            // Name
            VStack(alignment: .leading, spacing: 6) {
                Text("指令名称")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(BrandColors.textPrimary)
                StyledTextField(text: $name, placeholder: "例如: 📧 邮件润色", becomeFirstResponderOnAppear: isNewPrompt)
                    .padding(8)
                    .background(BrandColors.bgSecondary)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(BrandColors.border, lineWidth: 1)
                    )
            }

            // Template
            VStack(alignment: .leading, spacing: 6) {
                Text("Prompt 模板")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(BrandColors.textPrimary)
                Text("使用 {{text}} 作为原文占位符")
                    .font(.system(size: 11))
                    .foregroundColor(BrandColors.textMuted)

                TextEditor(text: $template)
                    .font(.system(size: 13))
                    .foregroundColor(BrandColors.textPrimary)
                    .lineSpacing(4)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(BrandColors.bgSecondary)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(BrandColors.border, lineWidth: 1)
                    )
                    .frame(minHeight: 120)
            }

            // Buttons
            HStack {
                Spacer()
                Button("取消") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("保存") {
                    onSave(name, template)
                }
                .buttonStyle(.borderedProminent)
                .tint(BrandColors.accent)
                .controlSize(.small)
                .disabled(!isValid)
            }
        }
        .padding(24)
        .frame(width: 420)
        .background(BrandColors.bgPanel)
        .onAppear {
            name = prompt?.name ?? ""
            template = prompt?.promptTemplate ?? ""
            if isNewPrompt {
                focusedField = .name
            }
        }
    }
}
