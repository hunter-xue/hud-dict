import AppKit
import SwiftUI

/// 设置窗口（独立普通窗口）。
public final class SettingsWindowController {
    private var window: NSWindow?
    private weak var panelController: PanelController?

    public init(panelController: PanelController?) {
        self.panelController = panelController
    }

    public func show(settings: SettingsStore, onHotKeyChanged: @escaping () -> Void) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let view = SettingsView(
            settings: settings,
            onHotKeyChanged: onHotKeyChanged,
            onOpacityChanged: { [weak self] value in
                Task { @MainActor in
                    self?.panelController?.opacity = value
                }
            }
        )
        let hosting = NSHostingController(rootView: view)
        let win = NSWindow(contentViewController: hosting)
        win.title = "HudDict 设置"
        win.styleMask = [.titled, .closable]
        win.isReleasedWhenClosed = false
        win.center()
        window = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}