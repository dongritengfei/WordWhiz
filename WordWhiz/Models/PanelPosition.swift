import Foundation
import AppKit

enum PanelPosition: String, CaseIterable, Codable {
    case screenRight = "right"
    case screenLeft = "left"
    case screenCenter = "center"

    var displayName: String {
        switch self {
        case .screenRight: return "屏幕右侧"
        case .screenLeft: return "屏幕左侧"
        case .screenCenter: return "屏幕中央"
        }
    }

    func calculateOrigin(panelSize: NSSize) -> NSPoint {
        guard let screen = NSScreen.main else {
            return NSPoint(x: 100, y: 100)
        }
        let visibleFrame = screen.visibleFrame

        switch self {
        case .screenRight:
            let x = visibleFrame.maxX - panelSize.width - 20
            let y = visibleFrame.midY - panelSize.height / 2
            return NSPoint(x: x, y: max(y, visibleFrame.minY))

        case .screenLeft:
            let x = visibleFrame.minX + 20
            let y = visibleFrame.midY - panelSize.height / 2
            return NSPoint(x: x, y: max(y, visibleFrame.minY))

        case .screenCenter:
            let x = visibleFrame.midX - panelSize.width / 2
            let y = visibleFrame.midY - panelSize.height / 2
            return NSPoint(x: x, y: max(y, visibleFrame.minY))
        }
    }
}
