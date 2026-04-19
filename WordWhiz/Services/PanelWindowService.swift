import SwiftUI
import AppKit

// MARK: - Custom Floating Panel

class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class PanelWindowService {
    private var panel: FloatingPanel?
    private let panelViewModel: PanelViewModel
    private let settingsViewModel: SettingsViewModel
    private var deactivateObserver: NSObjectProtocol?
    private var frameObserver: NSKeyValueObservation?

    init(panelViewModel: PanelViewModel, settingsViewModel: SettingsViewModel) {
        self.panelViewModel = panelViewModel
        self.settingsViewModel = settingsViewModel
        setupDeactivateObserver()
    }

    private func setupDeactivateObserver() {
        deactivateObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppDeactivated()
        }
    }

    private func setupFrameObserver(for panel: FloatingPanel) {
        // Observe frame changes to save position when pinned and dragged
        frameObserver = panel.observe(\.frame, options: [.old, .new]) { [weak self] panel, change in
            guard let self = self, self.panelViewModel.isPinned else { return }
            // Only save if the change is significant (user drag, not initial setup)
            if let oldFrame = change.oldValue, let newFrame = change.newValue {
                let moved = abs(oldFrame.origin.x - newFrame.origin.x) > 1 || abs(oldFrame.origin.y - newFrame.origin.y) > 1
                if moved {
                    self.savePosition(panel)
                }
            }
        }
    }

    private func handleAppDeactivated() {
        // Only hide if not pinned
        guard !panelViewModel.isPinned else { return }
        hide()
    }

    deinit {
        if let observer = deactivateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        frameObserver?.invalidate()
    }

    func show(sourceText: String) {
        let panel = getOrCreatePanel()

        // Update view model with source text
        panelViewModel.sourceText = sourceText

        // Refresh custom prompts from SwiftData
        panelViewModel.loadCustomPrompts()

        // Calculate position
        restoreOrCalculatePosition(for: panel)

        // Apply pin state
        panel.hidesOnDeactivate = !panelViewModel.isPinned

        // Activate app so floating panel is visible
        NSApp.activate(ignoringOtherApps: true)

        // Show panel — use orderFrontRegardless for maximum reliability
        panel.orderFrontRegardless()
        panel.makeKey()

        // Start optimization automatically
        panelViewModel.optimize()
    }

    func hide() {
        guard let panel else { return }

        let currentFrame = panel.frame
        let slideOutFrame = NSRect(
            x: currentFrame.origin.x + Constants.slideAnimationOffset,
            y: currentFrame.origin.y,
            width: currentFrame.width,
            height: currentFrame.height
        )

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = Constants.slideAnimationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(slideOutFrame, display: true)
            panel.animator().alphaValue = 0
        }, completionHandler: {
            panel.orderOut(nil)
            panel.setFrame(currentFrame, display: false)
            panel.alphaValue = 1
        })

        savePosition(panel)
    }

    func toggleVisibility(sourceText: String? = nil) {
        if let panel, panel.isVisible {
            hide()
        } else {
            show(sourceText: sourceText ?? "")
        }
    }

    func updatePinState(_ isPinned: Bool) {
        panel?.hidesOnDeactivate = !isPinned
    }

    // MARK: - Panel Creation

    private func getOrCreatePanel() -> FloatingPanel {
        if let existingPanel = panel {
            return existingPanel
        }

        let newPanel = FloatingPanel(
            contentRect: NSRect(
                x: 0, y: 0,
                width: Constants.panelWidth,
                height: Constants.panelHeight
            ),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )

        // Configure as floating panel
        newPanel.level = .floating
        newPanel.isFloatingPanel = true
        newPanel.isMovableByWindowBackground = true
        newPanel.titlebarAppearsTransparent = true
        newPanel.titleVisibility = .hidden
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = true
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        newPanel.hidesOnDeactivate = false
        newPanel.isReleasedWhenClosed = false

        // Set content view
        let hostingView = NSHostingView(
            rootView: OptimizationPanelView()
                .environment(panelViewModel)
                .environment(settingsViewModel)
        )
        hostingView.frame = newPanel.contentView?.frame ?? .zero
        hostingView.autoresizingMask = [.width, .height]

        // Remove default content view and set our own
        newPanel.contentView?.removeFromSuperview()
        newPanel.contentView = hostingView

        // Setup frame observer to track dragging when pinned
        setupFrameObserver(for: newPanel)

        self.panel = newPanel
        return newPanel
    }

    // MARK: - Position Management

    private func restoreOrCalculatePosition(for panel: FloatingPanel) {
        // If pinned, try to restore saved position first (user dragged to custom position)
        if panelViewModel.isPinned {
            if let frameString = UserDefaults.standard.string(forKey: Constants.panelPinnedFrameKey) {
                let frame = NSRectFromString(frameString)
                let screens = NSScreen.screens
                let isOnScreen = screens.contains { screen in
                    screen.visibleFrame.intersects(frame)
                }
                if isOnScreen {
                    panel.setFrame(frame, display: false)
                    return
                }
            }
        }

        // Not pinned or no saved pinned position - use setting
        let positionRawValue = UserDefaults.standard.string(forKey: Constants.panelPositionKey) ?? PanelPosition.screenRight.rawValue
        let position = PanelPosition(rawValue: positionRawValue) ?? .screenRight
        let origin = position.calculateOrigin(panelSize: panel.frame.size)
        panel.setFrameOrigin(origin)
    }

    private func savePosition(_ panel: FloatingPanel) {
        // Only save position when pinned (custom dragged position)
        if panelViewModel.isPinned {
            let frameString = NSStringFromRect(panel.frame)
            UserDefaults.standard.set(frameString, forKey: Constants.panelPinnedFrameKey)
        }
    }
}
