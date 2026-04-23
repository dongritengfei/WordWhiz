import SwiftUI

struct ModeSelectorView: View {
    @Environment(PanelViewModel.self) var viewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    // All prompts from customPrompts array, sorted by sortOrder
                    ForEach(Array(viewModel.customPrompts.enumerated()), id: \.element.id) { index, prompt in
                        ModeTabButton(
                            name: prompt.name,
                            shortcutIndex: index < 9 ? index + 1 : nil,
                            isSelected: viewModel.selectedPrompt?.id == prompt.id
                        ) {
                            viewModel.switchToPrompt(prompt)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 4)
            }

            Divider().background(BrandColors.border)
        }
        .padding(.vertical, 8)
    }
}

struct ModeTabButton: View {
    let name: String
    var shortcutIndex: Int? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(name)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : BrandColors.textSecondary)

                if let index = shortcutIndex {
                    Text("⌘\(index)")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(isSelected ? .white.opacity(0.7) : BrandColors.textMuted)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(isSelected ? BrandColors.accent : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.borderless)
        .contentShape(Rectangle())
    }
}
