import SwiftUI

struct StreamingStatusView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SkeletonLine(width: 1.0)
            SkeletonLine(width: 0.9)
            SkeletonLine(width: 0.7)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BrandColors.bgSecondary)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(BrandColors.border, lineWidth: 1)
        )
        .frame(minHeight: 140)
    }
}

struct SkeletonLine: View {
    let width: CGFloat
    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(BrandColors.bgTertiary)
            .frame(height: 14)
            .frame(maxWidth: .infinity)
            .scaleEffect(x: width, y: 1, anchor: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(isAnimating ? 0.08 : 0),
                                Color.white.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .animation(
                .easeInOut(duration: 1.5).repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
}
