import SwiftUI

struct PanelHeaderView: View {
    @Environment(PanelViewModel.self) var viewModel

    var body: some View {
        HStack {
            // Brand logo
            HStack(spacing: 8) {
                Text("Ww")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 22, height: 22)
                    .background(BrandColors.accent)
                    .cornerRadius(6)

                Text("WordWhiz")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(BrandColors.textPrimary)
            }

            Spacer()

            // Action buttons
            HStack(spacing: 6) {
                if viewModel.streamingStatus.isStreaming {
                    Button {
                        viewModel.stopStreaming()
                    } label: {
                        Image(systemName: "stop.fill")
                            .foregroundColor(BrandColors.red)
                            .font(.system(size: 12))
                            .frame(width: 28, height: 28)
                            .background(BrandColors.bgTertiary)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }

                Button {
                    viewModel.regenerate()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(BrandColors.textSecondary)
                        .font(.system(size: 12))
                        .frame(width: 28, height: 28)
                        .background(BrandColors.bgTertiary)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .disabled(viewModel.streamingStatus.isStreaming)

                Button {
                    AppDelegate.shared?.openSettings()
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundColor(BrandColors.textSecondary)
                        .font(.system(size: 12))
                        .frame(width: 28, height: 28)
                        .background(BrandColors.bgTertiary)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())

                Button {
                    viewModel.isPinned.toggle()
                    AppDelegate.shared?.getPanelWindowService()?.updatePinState(viewModel.isPinned)
                } label: {
                    Image(systemName: viewModel.isPinned ? "pin.fill" : "pin")
                        .foregroundColor(viewModel.isPinned ? BrandColors.accent : BrandColors.textSecondary)
                        .font(.system(size: 12))
                        .frame(width: 28, height: 28)
                        .background(BrandColors.bgTertiary)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())

                Button {
                    AppDelegate.shared?.getPanelWindowService()?.hide()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(BrandColors.textSecondary)
                        .font(.system(size: 12, weight: .medium))
                        .frame(width: 28, height: 28)
                        .background(BrandColors.bgTertiary)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(BrandColors.bgPanel)
    }
}
