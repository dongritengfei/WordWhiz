import SwiftUI

struct SourceSectionView: View {
    @Environment(PanelViewModel.self) var viewModel

    var body: some View {
        VStack(spacing: 0) {
            // Section header
            HStack {
                Text("原文")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(BrandColors.textMuted)
                    .textCase(.uppercase)

                if !viewModel.sourceText.isEmpty {
                    Text("\(viewModel.sourceText.count) 字")
                        .font(.system(size: 11))
                        .foregroundColor(BrandColors.textMuted)
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.isSourceCollapsed.toggle()
                    }
                } label: {
                    Text(viewModel.isSourceCollapsed ? "展开 ▾" : "收起 ▴")
                        .font(.system(size: 12))
                        .foregroundColor(BrandColors.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Source text display
            if !viewModel.sourceText.isEmpty {
                Text(viewModel.sourceText)
                    .font(.system(size: 13))
                    .lineSpacing(4)
                    .foregroundColor(BrandColors.textSecondary)
                    .lineLimit(viewModel.isSourceCollapsed ? 1 : Constants.sourceMaxLines)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)
                    .overlay(alignment: .bottom) {
                        // Only show gradient when text is expanded and likely truncated
                        if !viewModel.isSourceCollapsed {
                            let lineCount = viewModel.sourceText.components(separatedBy: .newlines).count
                            if lineCount > Constants.sourceMaxLines {
                                LinearGradient(
                                    colors: [BrandColors.bgPanel.opacity(0), BrandColors.bgPanel],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 24)
                                .allowsHitTesting(false)
                            }
                        }
                    }
            }

            Divider().background(BrandColors.border)
        }
    }
}
