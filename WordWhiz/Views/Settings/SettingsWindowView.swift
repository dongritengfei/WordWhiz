import SwiftUI

struct SettingsWindowView: View {
    @Environment(SettingsViewModel.self) var viewModel

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(spacing: 0) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    HStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 14))
                            .frame(width: 20)
                        Text(tab.displayName)
                            .font(.system(size: 13))
                        Spacer()
                    }
                    .foregroundColor(viewModel.selectedSettingsTab == tab ? .white : BrandColors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(viewModel.selectedSettingsTab == tab ? BrandColors.accent : Color.clear)
                    .cornerRadius(6)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.selectedSettingsTab = tab
                    }
                }

                Spacer()
            }
            .padding(8)
            .frame(width: 170)
            .background(BrandColors.bgSecondary)

            // Content
            ScrollView {
                switch viewModel.selectedSettingsTab {
                case .general:
                    GeneralSettingsView()
                case .api:
                    APISettingsView()
                case .prompts:
                    CustomPromptsView()
                case .history:
                    HistorySettingsView()
                case .shortcuts:
                    ShortcutSettingsView()
                case .about:
                    AboutView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(BrandColors.bgPanel)
        .frame(width: 640, height: 520)
    }
}
