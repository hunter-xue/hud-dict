import Foundation

/// 非密钥设置的持久化（UserDefaults）：Base URL、模型名、热键、目标语言、透明度。
/// 不引用 AppKit。
public final class SettingsStore {
    private let defaults: UserDefaults

    private enum Key {
        static let baseURL = "llm.baseURL"
        static let model = "llm.model"
        static let targetLanguage = "ui.targetLanguage"
        static let opacity = "ui.opacity"
        static let hotKeyCode = "hotkey.keyCode"
        static let hotKeyModifiers = "hotkey.modifiers"
    }

    public static let defaultTargetLanguage = "简体中文"
    public static let defaultOpacity: Double = 0.95
    /// 默认热键：⌘⌥⇧D（避开与系统功能冲突的 ⌘⌥D）
    public static let defaultHotKeyCode: UInt32 = 0x02  // D
    public static let defaultHotKeyModifiers: UInt32 = 0x0B00  // command | option | shift

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var baseURL: String {
        get { defaults.string(forKey: Key.baseURL) ?? "" }
        set { defaults.set(newValue, forKey: Key.baseURL) }
    }

    public var model: String {
        get { defaults.string(forKey: Key.model) ?? "" }
        set { defaults.set(newValue, forKey: Key.model) }
    }

    public var targetLanguage: String {
        get { defaults.string(forKey: Key.targetLanguage) ?? Self.defaultTargetLanguage }
        set { defaults.set(newValue, forKey: Key.targetLanguage) }
    }

    public var opacity: Double {
        // 下限 0.8：面板为固定深色底，过低的透明度会削弱文字对比度。
        get { min(max(defaults.object(forKey: Key.opacity) as? Double ?? Self.defaultOpacity, 0.8), 1.0) }
        set { defaults.set(min(max(newValue, 0.8), 1.0), forKey: Key.opacity) }
    }

    public var hotKeyCode: UInt32 {
        get { defaults.object(forKey: Key.hotKeyCode) as? UInt32 ?? Self.defaultHotKeyCode }
        set { defaults.set(newValue, forKey: Key.hotKeyCode) }
    }

    public var hotKeyModifiers: UInt32 {
        get { defaults.object(forKey: Key.hotKeyModifiers) as? UInt32 ?? Self.defaultHotKeyModifiers }
        set { defaults.set(newValue, forKey: Key.hotKeyModifiers) }
    }

    public var llmSettings: LLMSettings {
        get { LLMSettings(baseURL: baseURL, model: model) }
        set {
            baseURL = LLMSettings.normalizeBaseURL(newValue.baseURL)
            model = newValue.model
        }
    }

    public var isLLMConfigured: Bool {
        !LLMSettings.normalizeBaseURL(baseURL).isEmpty && !model.isEmpty && KeychainStore.hasKey
    }
}