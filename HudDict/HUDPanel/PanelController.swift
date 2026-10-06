import AppKit
import SwiftUI

/// 管理主面板的显示/隐藏/透明度，以及查询状态。仅在主线程使用。
@MainActor
public final class PanelController {
    private let panel: HUDPanel
    private let settings: SettingsStore
    private let model: PanelModel

    /// 透明度：直接作用于面板，并持久化。设置界面改动即时生效。
    public var opacity: Double {
        get { settings.opacity }
        set {
            settings.opacity = newValue
            panel.alphaValue = newValue
        }
    }

    public init(settings: SettingsStore, wordBook: WordBook) {
        self.settings = settings
        self.model = PanelModel(settings: settings, wordBook: wordBook)

        let contentRect = NSRect(x: 0, y: 0, width: 420, height: 300)
        panel = HUDPanel(contentRect: contentRect)
        panel.alphaValue = settings.opacity

        let hosting = NSHostingView(rootView: PanelView(model: model))
        hosting.translatesAutoresizingMaskIntoConstraints = false

        // 用一个容器承载 SwiftUI 内容，并在顶部叠加拖动条。
        let container = NSView(frame: contentRect)
        container.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: container.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        let dragStrip = WindowDragStrip()
        dragStrip.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(dragStrip)
        NSLayoutConstraint.activate([
            dragStrip.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            dragStrip.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            dragStrip.topAnchor.constraint(equalTo: container.topAnchor),
            dragStrip.heightAnchor.constraint(equalToConstant: WindowDragStrip.height),
        ])

        panel.contentView = container
    }

    public func toggle() {
        if panel.isVisible {
            hide()
        } else {
            show()
        }
    }

    public func show() {
        model.resetForNewSession()
        panel.alphaValue = settings.opacity
        centerIfOffscreen()
        // 不激活应用地显示
        panel.orderFrontRegardless()
        panel.makeKey()
        model.requestFocus()
    }

    public func hide() {
        panel.orderOut(nil)
    }

    private func centerIfOffscreen() {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        if !visible.intersects(panel.frame) {
            let size = panel.frame.size
            let origin = NSPoint(
                x: visible.midX - size.width / 2,
                y: visible.midY - size.height / 2
            )
            panel.setFrameOrigin(origin)
        }
    }
}