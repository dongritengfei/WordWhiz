import SwiftUI

struct ModeSelectorView: View {
    @Environment(PanelViewModel.self) var viewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    // All prompts from customPrompts array, sorted by sortOrder
                    ForEach(viewModel.customPrompts) { prompt in
                        ModeTabButton(
                            name: prompt.name,
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
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.system(size: 12))
                .foregroundColor(isSelected ? .white : BrandColors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(isSelected ? BrandColors.accent : Color.clear)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}
