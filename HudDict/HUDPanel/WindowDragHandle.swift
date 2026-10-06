import AppKit

/// 无边框面板顶部的拖动条（纯 AppKit，直接作为 contentView 的子视图叠加在 SwiftUI 之上）。
///
/// 为什么不放在 SwiftUI 里：SwiftUI 内容（TextField 等）会吃掉鼠标事件，
/// 通过 NSViewRepresentable 放在 SwiftUI 树里命中区域不稳定。这里直接作为
/// NSHostingView 之上的兄弟视图，横向铺满面板顶部，保证收到 mouseDown。
///
/// 该视图会自绘一条淡淡的背景和一个居中的手柄，让用户一眼看出这里是拖动区。
public final class WindowDragStrip: NSView {
    /// 拖动条高度。
    public static let height: CGFloat = 22

    private var hovered = false
    private var trackingArea: NSTrackingArea?

    public override func draw(_ dirtyRect: NSRect) {
        // 背景：悬停时更明显，平时很淡。
        let bg = NSColor.white.withAlphaComponent(hovered ? 0.10 : 0.04)
        bg.setFill()
        bounds.fill()

        // 居中手柄
        let handleWidth: CGFloat = 40
        let handleHeight: CGFloat = 4
        let handleRect = NSRect(
            x: (bounds.width - handleWidth) / 2,
            y: (bounds.height - handleHeight) / 2,
            width: handleWidth,
            height: handleHeight
        )
        let handlePath = NSBezierPath(roundedRect: handleRect, xRadius: handleHeight / 2, yRadius: handleHeight / 2)
        NSColor.secondaryLabelColor.withAlphaComponent(hovered ? 0.9 : 0.6).setFill()
        handlePath.fill()

        // 光标：悬停时显示可移动手势。
        if hovered { NSCursor.openHand.set() }
    }

    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea { removeTrackingArea(trackingArea) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    public override func mouseEntered(with event: NSEvent) {
        hovered = true
        needsDisplay = true
    }

    public override func mouseExited(with event: NSEvent) {
        hovered = false
        needsDisplay = true
    }

    public override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }

    /// 让窗口背景拖动逻辑也认可这块区域。
    public override var mouseDownCanMoveWindow: Bool { true }

    /// 整条都响应拖动。
    public override func hitTest(_ point: NSPoint) -> NSView? {
        bounds.contains(point) ? self : nil
    }
}