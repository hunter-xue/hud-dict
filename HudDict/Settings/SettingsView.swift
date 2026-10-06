import SwiftUI
import Carbon.HIToolbox

/// 设置界面：Base URL、模型名、API Key、热键、目标语言、透明度、连通测试。
public struct SettingsView: View {
    let settings: SettingsStore
    let onHotKeyChanged: () -> Void
    let onOpacityChanged: (Double) -> Void

    @State private var baseURL: String
    @State private var model: String
    @State private var apiKey: String = ""
    @State private var keySaved: Bool
    @State private var targetLanguage: String
    @State private var opacity: Double
    @State private var testResult: String?
    @State private var isTesting = false
    private let hotKeyDescription: String

    private let client = ExplainClient()

    public init(
        settings: SettingsStore,
        onHotKeyChanged: @escaping () -> Void,
        onOpacityChanged: @escaping (Double) -> Void
    ) {
        self.settings = settings
        self.onHotKeyChanged = onHotKeyChanged
        self.onOpacityChanged = onOpacityChanged
        _baseURL = State(initialValue: settings.baseURL)
        _model = State(initialValue: settings.model)
        _keySaved = State(initialValue: KeychainStore.hasKey)
        _targetLanguage = State(initialValue: settings.targetLanguage)
        _opacity = State(initialValue: settings.opacity)
        self.hotKeyDescription = HotKeyDescription.describe(
            keyCode: settings.hotKeyCode, modifiers: settings.hotKeyModifiers)
    }

    public var body: some View {
        Form {
            Section("LLM 设置") {
                TextField("Base URL", text: $baseURL, prompt: Text("https://api.openai.com"))
                TextField("模型名", text: $model, prompt: Text("如 gpt-4o-mini"))
                HStack {
                    SecureField(
                        "API Key",
                        text: $apiKey,
                        prompt: Text(keySaved ? "已保存（留空沿用旧密钥）" : "填写你的 API Key")
                    )
                    Button("清除") {
                        KeychainStore.delete()
                        apiKey = ""
                        keySaved = false
                    }
                }
                HStack {
                    Button("保存") { save() }
                    Button("连通测试") { test() }
                        .disabled(isTesting)
                    if isTesting { ProgressView().controlSize(.small) }
                }
                if let testResult {
                    Text(testResult).font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }

            Section("热键") {
                LabeledContent("当前热键", value: hotKeyDescription)
                Text("改热键请在设置中用预设：⌘⌥⇧D（默认）")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }

            Section {
                TextField("目标语言", text: $targetLanguage, prompt: Text("如 简体中文、English、日本語"))
                HStack {
                    Text("透明度")
                    Slider(value: $opacity, in: 0.8...1.0)
                        .onChange(of: opacity) { _, newValue in
                            settings.opacity = newValue
                            onOpacityChanged(newValue)
                        }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 520)
        .onDisappear { save() }
    }

    private func save() {
        var llm = LLMSettings(baseURL: baseURL, model: model)
        llm.baseURL = LLMSettings.normalizeBaseURL(llm.baseURL)
        baseURL = llm.baseURL
        settings.llmSettings = llm
        // 密钥：留空沿用旧密钥；非空则覆盖。
        if !apiKey.isEmpty {
            KeychainStore.save(apiKey)
            apiKey = ""
            keySaved = true
        }
        settings.targetLanguage = targetLanguage
        settings.opacity = opacity
        onHotKeyChanged()
    }

    private func test() {
        isTesting = true
        testResult = nil
        save()
        guard let key = KeychainStore.load() else {
            testResult = "请先填写并保存 API Key。"
            isTesting = false
            return
        }
        client.testConnection(settings: settings.llmSettings, apiKey: key) { error in
            DispatchQueue.main.async {
                isTesting = false
                testResult = error?.errorDescription ?? "连接成功。"
            }
        }
    }
}

/// 把热键键码/修饰符描述成可读文本。
public enum HotKeyDescription {
    public static func describe(keyCode: UInt32, modifiers: UInt32) -> String {
        var parts: [String] = []
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        parts.append(letter(for: keyCode))
        return parts.joined()
    }

    private static func letter(for keyCode: UInt32) -> String {
        // kVK_ANSI_D = 0x02
        switch keyCode {
        case 0x02: return "D"
        case 0x00: return "A"
        case 0x01: return "S"
        case 0x03: return "F"
        default: return "?"
        }
    }
}