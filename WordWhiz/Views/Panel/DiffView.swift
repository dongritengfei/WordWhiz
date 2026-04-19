import SwiftUI

struct DiffView: View {
    @Environment(PanelViewModel.self) var viewModel

    private var diffSegments: [DiffCalculator.DiffSegment] {
        DiffCalculator.computeDiff(source: viewModel.sourceText, result: viewModel.resultText)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(diffSegments.enumerated()), id: \.offset) { index, segment in
                    switch segment.type {
                    case .removed:
                        Text(segment.text)
                            .font(.system(size: 13))
                            .lineSpacing(4)
                            .foregroundColor(BrandColors.red.opacity(0.6))
                            .strikethrough()
                    case .added:
                        Text(segment.text)
                            .font(.system(size: 13))
                            .lineSpacing(4)
                            .foregroundColor(BrandColors.green)
                    case .unchanged:
                        Text(segment.text)
                            .font(.system(size: 13))
                            .lineSpacing(4)
                            .foregroundColor(BrandColors.textSecondary)
                    }
                }

                if diffSegments.isEmpty && !viewModel.sourceText.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("原文")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(BrandColors.textMuted)
                            .textCase(.uppercase)

                        Text(viewModel.sourceText)
                            .font(.system(size: 13))
                            .lineSpacing(4)
                            .foregroundColor(BrandColors.textSecondary)

                        Divider().background(BrandColors.border)

                        Text("优化后")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(BrandColors.textMuted)
                            .textCase(.uppercase)

                        Text(viewModel.resultText)
                            .font(.system(size: 13))
                            .lineSpacing(4)
                            .foregroundColor(BrandColors.green)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(BrandColors.bgSecondary)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(BrandColors.border, lineWidth: 1)
        )
        .frame(minHeight: 140)
    }
}
