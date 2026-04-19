import SwiftUI
import SwiftData

struct HistorySettingsView: View {
    @State private var historyVM = HistoryViewModel()
    @State private var searchText: String = ""
    @State private var selectedRecord: OptimizationRecord?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("历史记录")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(BrandColors.textPrimary)

                Spacer()

                if !historyVM.records.isEmpty {
                    Button("清除全部") {
                        historyVM.clearAllHistory()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundColor(BrandColors.red)
                }
            }
            .padding(.bottom, 16)

            // Search bar
            TextField("搜索历史记录...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(BrandColors.textPrimary)
                .padding(8)
                .background(BrandColors.bgSecondary)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(BrandColors.border, lineWidth: 1)
                )
                .onChange(of: searchText) {
                    historyVM.search(searchText)
                }
                .padding(.bottom, 12)

            // Records list
            if historyVM.records.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 24))
                        .foregroundColor(BrandColors.textMuted)
                    Text("暂无历史记录")
                        .font(.system(size: 13))
                        .foregroundColor(BrandColors.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(historyVM.records) { record in
                            HistoryRecordCard(record: record) {
                                ClipboardService.shared.write(record.resultText)
                            } onDelete: {
                                historyVM.deleteRecord(record)
                            }
                        }
                    }
                }
            }
        }
        .padding(24)
        .onAppear {
            if let context = modelContextFromApp {
                historyVM.setModelContext(context)
            }
        }
    }

    private var modelContextFromApp: ModelContext? {
        let container = try? ModelContainer(for: OptimizationRecord.self, CustomPrompt.self)
        return container.flatMap { ModelContext($0) }
    }
}

struct HistoryRecordCard: View {
    let record: OptimizationRecord
    let onCopy: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(record.promptName ?? "优化")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(BrandColors.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(BrandColors.accent.opacity(0.15))
                    .cornerRadius(4)

                Spacer()

                Text(record.createdAt.formattedString())
                    .font(.system(size: 11))
                    .foregroundColor(BrandColors.textMuted)

                Button {
                    onCopy()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11))
                        .foregroundColor(BrandColors.textMuted)
                }
                .buttonStyle(.plain)

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(BrandColors.textMuted)
                }
                .buttonStyle(.plain)
            }

            Text(record.resultText)
                .font(.system(size: 13))
                .foregroundColor(BrandColors.textSecondary)
                .lineLimit(2)
        }
        .padding(14)
        .background(BrandColors.bgSecondary)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(BrandColors.border, lineWidth: 1)
        )
    }
}
