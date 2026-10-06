import AppKit

/// 程序入口。菜单栏应用，无 SwiftUI App 生命周期。
MainActor.assumeIsolated {
    let delegate = AppDelegate()
    let app = NSApplication.shared
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    app.run()
}