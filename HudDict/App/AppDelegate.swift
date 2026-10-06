import AppKit

/// 菜单栏应用入口。不使用 SwiftUI App，直接以 AppDelegate 启动。
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var hotKeyManager: HotKeyManager!
    private let settings = SettingsStore()
    private let wordBookStore = WordBookStore()
    private lazy var wordBook = WordBook(store: wordBookStore)
    private var panelController: PanelController!
    private lazy var settingsWindow = SettingsWindowController(panelController: panelController)
    private lazy var wordBookWindow = WordBookWindowController(wordBook: wordBook, store: wordBookStore)

    func applicationDidFinishLaunching(_ notification: Notification) {
        wordBook.onSaveError = { error in
            NSLog("HudDict: 单词本写盘失败：\(error.localizedDescription)")
        }

        panelController = PanelController(settings: settings, wordBook: wordBook)

        setupStatusItem()
        setupHotKey()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "character.book.closed", accessibilityDescription: "HudDict")
        statusItem.button?.action = #selector(statusItemClicked(_:))
        statusItem.button?.target = self
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            panelController.toggle()
            return
        }
        // 左键固定 toggle 主面板；右键弹菜单。
        if event.type == .rightMouseUp {
            showMenu()
        } else {
            panelController.toggle()
        }
    }

    private func setupHotKey() {
        hotKeyManager = HotKeyManager { [weak self] in
            DispatchQueue.main.async { self?.panelController.toggle() }
        }
        hotKeyManager.register(keyCode: settings.hotKeyCode, modifiers: settings.hotKeyModifiers)
    }

    // MARK: - 菜单（右键菜单栏图标）

    @objc private func showMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "显示/隐藏面板", action: #selector(togglePanel), keyEquivalent: "").target = self
        menu.addItem(withTitle: "设置…", action: #selector(openSettings), keyEquivalent: "").target = self
        menu.addItem(withTitle: "单词本…", action: #selector(openWordBook), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "退出", action: #selector(quit), keyEquivalent: "q").target = self
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func togglePanel() { panelController.toggle() }

    @objc private func openSettings() {
        settingsWindow.show(settings: settings) { [weak self] in
            guard let self else { return }
            self.hotKeyManager.register(keyCode: self.settings.hotKeyCode, modifiers: self.settings.hotKeyModifiers)
        }
    }

    @objc private func openWordBook() { wordBookWindow.show() }

    @objc private func quit() { NSApp.terminate(nil) }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }
}