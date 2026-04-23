import SwiftUI
import AppKit

struct OptimizationPanelView: View {
    @Environment(PanelViewModel.self) var viewModel
    @FocusState private var isResultEditorFocused: Bool

    var body: some View {
        mainContent
            .background(PanelKeyboardHandler(viewModel: viewModel))
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            PanelHeaderView()
            ModeSelectorView()
            SourceSectionView()
            ResultSectionView(isEditorFocused: $isResultEditorFocused)
        }
        .background(BrandColors.bgPanel)
        .clipShape(RoundedRectangle(cornerRadius: Constants.panelCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Constants.panelCornerRadius)
                .stroke(BrandColors.border, lineWidth: 1)
        )
        .frame(width: Constants.panelWidth, height: Constants.panelHeight)
    }
}

// MARK: - Keyboard Handler via NSViewRepresentable

private struct PanelKeyboardHandler: NSViewRepresentable {
    let viewModel: PanelViewModel

    func makeNSView(context: Context) -> KeyMonitorNSView {
        let view = KeyMonitorNSView()
        view.viewModel = viewModel
        return view
    }

    func updateNSView(_ nsView: KeyMonitorNSView, context: Context) {
        nsView.viewModel = viewModel
    }
}

private class KeyMonitorNSView: NSView {
    var viewModel: PanelViewModel?
    private var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil && monitor == nil {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                return self?.handleKeyEvent(event) ?? event
            }
        } else if window == nil, let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // ESC: hide panel
        if event.keyCode == 53 {
            AppDelegate.shared?.getPanelWindowService()?.hide()
            return nil
        }

        // Cmd+1-9: switch to prompt by index
        if modifiers == .command, let chars = event.characters, let num = Int(chars), num >= 1 {
            let prompts = viewModel?.customPrompts ?? []
            if num <= prompts.count {
                viewModel?.switchToPrompt(prompts[num - 1])
            }
            return nil
        }

        // Cmd+R: regenerate
        if modifiers == .command, event.characters == "r" {
            viewModel?.regenerate()
            return nil
        }

        // Cmd+Shift+C: copy result
        if modifiers == [.command, .shift], event.characters == "c" {
            viewModel?.copyResult()
            return nil
        }

        return event
    }
}
