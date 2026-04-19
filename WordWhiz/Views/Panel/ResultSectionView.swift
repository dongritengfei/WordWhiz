import SwiftUI

struct ResultSectionView: View {
    @Environment(PanelViewModel.self) var viewModel
    @FocusState.Binding var isEditorFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Section header
            HStack {
                Text("优化结果")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(BrandColors.textMuted)
                    .textCase(.uppercase)

                if viewModel.resultCharacterCount > 0 {
                    Text("\(viewModel.resultCharacterCount) 字")
                        .font(.system(size: 11))
                        .foregroundColor(BrandColors.textMuted)
                }

                Spacer()

                if case .idle = viewModel.streamingStatus {
                    EmptyView()
                } else {
                    Text(viewModel.streamingStatus.label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(viewModel.streamingStatus.labelColor)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Content area
            Group {
                if viewModel.isShowingDiff {
                    DiffView()
                } else {
                    switch viewModel.streamingStatus {
                    case .idle:
                        if viewModel.resultText.isEmpty {
                            placeholderView
                        } else {
                            resultEditor
                        }

                    case .streaming:
                        if viewModel.resultText.isEmpty {
                            StreamingStatusView()
                        } else {
                            streamingTextView
                        }

                    case .complete, .stopped:
                        resultEditor

                    case .error(let message):
                        errorView(message)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 12)
        }
        .frame(maxHeight: .infinity)
        .onChange(of: viewModel.streamingStatus) { _, newStatus in
            if case .complete = newStatus {
                isEditorFocused = true
            }
        }
    }

    // MARK: - Sub Views

    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(BrandColors.bgSecondary)
            .overlay(
                Text("选中文本后按 ⌘. 开始优化")
                    .font(.system(size: 14))
                    .foregroundColor(BrandColors.textMuted)
            )
            .frame(minHeight: 140)
    }

    private var resultEditor: some View {
        TextEditor(text: Binding(
            get: { viewModel.resultText },
            set: { viewModel.resultText = $0 }
        ))
        .font(.system(size: 14))
        .lineSpacing(4)
        .foregroundColor(BrandColors.textPrimary)
        .scrollContentBackground(.hidden)
        .background(BrandColors.bgSecondary)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(BrandColors.border, lineWidth: 1)
        )
        .frame(minHeight: 140)
        .focused($isEditorFocused)
    }

    private var streamingTextView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(viewModel.resultText)
                        .font(.system(size: 14))
                        .lineSpacing(4)
                        .foregroundColor(BrandColors.textPrimary)

                    // Blinking cursor
                    Text("|")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(BrandColors.accent)
                        .blink()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .id("streaming")
            }
            .background(BrandColors.bgSecondary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(BrandColors.border, lineWidth: 1)
            )
            .frame(minHeight: 140)
            .onChange(of: viewModel.resultText) {
                withAnimation {
                    proxy.scrollTo("streaming", anchor: .bottom)
                }
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(BrandColors.bgSecondary)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(BrandColors.orange)
                        .font(.system(size: 20))
                    Text(message)
                        .font(.system(size: 13))
                        .foregroundColor(BrandColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            )
            .frame(minHeight: 140)
    }
}

// MARK: - Blink Animation

extension View {
    func blink() -> some View {
        self.modifier(BlinkModifier())
    }
}

struct BlinkModifier: ViewModifier {
    @State private var isVisible = true

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isVisible)
            .onAppear { isVisible = false }
    }
}
