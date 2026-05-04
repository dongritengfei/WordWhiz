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
        let defaults: [(name: String, template: String, sortOrder: Int)] = [
            (
                "✨ 润色",
                "你是一位专业的中文文案编辑。请对用户提供的文本进行润色优化，修正语法错误、改善措辞表达、提升文字质量，但保持原文核心意思不变。输出仅包含优化后的文本，不需要解释修改原因。\n\n需处理的文本：{{text}}",
                0
            ),
            (
                "🌍 翻译",
                "你是一位专业的翻译专家。请自动检测源语言：如果原文是中文则翻译为英文，如果原文是英文则翻译为中文。输出仅包含翻译后的文本，不需要解释。\n\n需处理的文本：{{text}}",
                1
            ),
            (
                "📋 摘要",
                "你是一位内容摘要专家。请将以下长文本压缩为核心要点，保留关键信息，输出简洁精炼的摘要。输出仅包含摘要文本。\n\n需处理的文本：{{text}}",
                2
            ),
            (
                "📝 扩写",
                "你是一位文案扩写专家。请在保持原意的基础上，丰富细节、增加论据、扩展表述，使内容更加充实完整。输出仅包含扩写后的文本。\n\n需处理的文本：{{text}}",
                3
            ),
            (
                "👔 正式化",
                "你是一位商务写作专家。请将以下文本转换为正式、规范的书面语，适用于商务邮件、官方文件等场景。保持原意不变，语气正式专业。输出仅包含转换后的文本。\n\n需处理的文本：{{text}}",
                4
            ),
            (
                "💬 口语化",
                "你是一位社交媒体文案专家。请将以下文本转换为自然、亲切的口语风格，适用于社交媒体、日常沟通等场景。保持原意不变，语气轻松活泼。输出仅包含转换后的文本。\n\n需处理的文本：{{text}}",
                5
            )
        ]

        for item in defaults {
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
