import SwiftUI

struct ActionBarView: View {
    @Environment(PanelViewModel.self) var viewModel
    @FocusState.Binding var isEditorFocused: Bool

    var body: some View {
        HStack {
            // Left side
            HStack(spacing: 6) {
                Button {
                    viewModel.regenerate()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                        .foregroundColor(BrandColors.textSecondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.streamingStatus.isStreaming)
            }

            Spacer()

            // Right side
            HStack(spacing: 8) {
                Button("全选文本") {
                    selectAllResultText()
                }
                .buttonStyle(.bordered)
                .font(.system(size: 13))
                .foregroundColor(BrandColors.textPrimary)
                .controlSize(.small)
                .disabled(viewModel.resultText.isEmpty || viewModel.streamingStatus.isStreaming)

                Button {
                    viewModel.copyResult()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.showCopiedFeedback ? "checkmark" : "doc.on.doc")
                        Text(viewModel.showCopiedFeedback ? "已复制" : "复制结果")
                    }
                    .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(BrandColors.accent)
                .controlSize(.small)
                .disabled(viewModel.resultText.isEmpty || viewModel.streamingStatus.isStreaming)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(BrandColors.bgPanel)
        .overlay(alignment: .top) {
            Divider().background(BrandColors.border)
        }
    }

    private func selectAllResultText() {
        // Focus the result editor and select all text
        isEditorFocused = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
        }
    }
}
