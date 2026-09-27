import SwiftUI
import SwiftData

struct CustomPromptsView: View {
    @Environment(SettingsViewModel.self) var viewModel
    @Environment(\.modelContext) private var modelContext

    @State private var prompts: [CustomPrompt] = []
    @State private var editingPrompt: CustomPrompt?
    @State private var isNewPrompt: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("指令管理")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(BrandColors.textPrimary)
                .padding(.bottom, 8)

            Text("管理所有优化指令。使用 `{{text}}` 作为原文占位符。点击上下箭头调整顺序，顺序将同步到优化面板。")
                .font(.system(size: 12))
                .foregroundColor(BrandColors.textMuted)
                .padding(.bottom, 16)

            ScrollView {
                VStack(spacing: 10) {
                    // Add button at top
                    Button {
                        isNewPrompt = true
                        editingPrompt = CustomPrompt(name: "", promptTemplate: "请优化以下文本：\n\n{{text}}")
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("添加新指令")
                        }
                        .font(.system(size: 13))
                        .foregroundColor(BrandColors.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                .foregroundColor(BrandColors.border)
                        )
                    }
                    .buttonStyle(.plain)

                    ForEach(Array(prompts.enumerated()), id: \.element.id) { index, prompt in
                        PromptCard(
                            prompt: prompt,
                            index: index,
                            totalCount: prompts.count,
                            onEdit: {
                                isNewPrompt = false
                                editingPrompt = prompt
                            },
                            onDelete: {
                                deletePrompt(prompt)
                            },
                            onMoveUp: {
                                movePrompt(at: index, direction: -1)
                            },
                            onMoveDown: {
                                movePrompt(at: index, direction: 1)
                            }
                        )
                    }
                }
            }
        }
        .padding(24)
        .sheet(item: $editingPrompt) { prompt in
            PromptEditorView(
                prompt: prompt,
                isNewPrompt: isNewPrompt,
                onSave: { name, template in
                    if isNewPrompt {
                        addPrompt(name: name, template: template)
                    } else {
                        updatePrompt(prompt, name: name, template: template)
                    }
                    editingPrompt = nil
                },
                onCancel: {
                    editingPrompt = nil
                }
            )
        }
        .onAppear {
            initializeDefaultPromptsIfNeeded()
            refreshPrompts()
        }
    }

    private func refreshPrompts() {
        let descriptor = FetchDescriptor<CustomPrompt>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        do {
            prompts = try modelContext.fetch(descriptor)
        } catch {
            prompts = []
        }
    }

    /// Initialize default prompts on first launch
    private func initializeDefaultPromptsIfNeeded() {
        let descriptor = FetchDescriptor<CustomPrompt>()
        if let existing = try? modelContext.fetch(descriptor), !existing.isEmpty {
            return
        }

        // Create default prompts
        for item in Constants.defaultPrompts {
            let prompt = CustomPrompt(
                name: item.name,
                promptTemplate: item.template,
                sortOrder: item.sortOrder
            )
            modelContext.insert(prompt)
        }

        try? modelContext.save()
    }

    private func addPrompt(name: String, template: String) {
        let prompt = CustomPrompt(
            name: name,
            promptTemplate: template,
            sortOrder: prompts.count
        )
        modelContext.insert(prompt)
        try? modelContext.save()
        refreshPrompts()
    }

    private func updatePrompt(_ prompt: CustomPrompt, name: String, template: String) {
        prompt.name = name
        prompt.promptTemplate = template
        prompt.updatedAt = Date()
        try? modelContext.save()
        refreshPrompts()
    }

    private func deletePrompt(_ prompt: CustomPrompt) {
        modelContext.delete(prompt)
        try? modelContext.save()
        // Reorder remaining prompts
        reorderPrompts()
        refreshPrompts()
    }

    private func reorderPrompts() {
        let descriptor = FetchDescriptor<CustomPrompt>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        if let allPrompts = try? modelContext.fetch(descriptor) {
            for (index, prompt) in allPrompts.enumerated() {
                prompt.sortOrder = index
            }
            try? modelContext.save()
        }
    }

    private func movePrompt(at index: Int, direction: Int) {
        let newIndex = index + direction
        guard newIndex >= 0 && newIndex < prompts.count else { return }

        // Swap sortOrder
        let currentPrompt = prompts[index]
        let targetPrompt = prompts[newIndex]

        let tempSortOrder = currentPrompt.sortOrder
        currentPrompt.sortOrder = targetPrompt.sortOrder
        targetPrompt.sortOrder = tempSortOrder

        try? modelContext.save()
        refreshPrompts()
    }
}

struct PromptCard: View {
    let prompt: CustomPrompt
    let index: Int
    let totalCount: Int
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(prompt.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(BrandColors.textPrimary)

                Spacer()

                // Move up button
                Button {
                    onMoveUp()
                } label: {
                    Image(systemName: "arrow.up")
                        .foregroundColor(index > 0 ? BrandColors.textMuted : BrandColors.border)
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .disabled(index == 0)

                // Move down button
                Button {
                    onMoveDown()
                } label: {
                    Image(systemName: "arrow.down")
                        .foregroundColor(index < totalCount - 1 ? BrandColors.textMuted : BrandColors.border)
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .disabled(index == totalCount - 1)

                // Edit button
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .foregroundColor(BrandColors.textMuted)
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)

                // Delete button
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(BrandColors.textMuted)
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
            }

            Text(prompt.preview)
                .font(.system(size: 12))
                .foregroundColor(BrandColors.textMuted)
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
