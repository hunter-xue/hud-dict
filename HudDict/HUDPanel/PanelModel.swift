import Foundation

/// 主面板的状态与查询流程。查询成功后写入单词本。仅在主线程使用。
@MainActor
public final class PanelModel: ObservableObject {
    @Published var input: String = ""
    @Published var translation: String = ""
    @Published var explanation: String = ""
    @Published var statusMessage: String?
    @Published var isStreaming = false
    /// 递增即请求视图把焦点移到输入框。
    @Published var focusRequest: Int = 0

    private let settings: SettingsStore
    private let wordBook: WordBook
    private let client = ExplainClient()

    public static let maxInputLength = 2000

    init(settings: SettingsStore, wordBook: WordBook) {
        self.settings = settings
        self.wordBook = wordBook
    }

    func requestFocus() {
        focusRequest &+= 1
    }

    /// 呼出小窗时调用：取消进行中的流并清空全部显示内容，作为一次全新会话。
    /// 不影响单词本、不重置 focusRequest（呼出后仍聚焦输入框）。
    func resetForNewSession() {
        client.cancel()
        input = ""
        translation = ""
        explanation = ""
        statusMessage = nil
        isStreaming = false
    }

    func submit() {
        guard !isStreaming else { return }
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            statusMessage = "请输入要查询的内容。"
            return
        }
        guard text.count <= Self.maxInputLength else {
            statusMessage = "输入过长，请控制在 \(Self.maxInputLength) 字符以内。"
            return
        }
        guard settings.isLLMConfigured, let apiKey = KeychainStore.load() else {
            statusMessage = "请先在设置里完成 LLM 配置。"
            return
        }

        translation = ""
        explanation = ""
        statusMessage = nil
        isStreaming = true

        client.stream(
            input: text,
            settings: settings.llmSettings,
            apiKey: apiKey,
            targetLanguage: settings.targetLanguage,
            onUpdate: { [weak self] translation, explanation in
                Task { @MainActor in
                    guard let self else { return }
                    self.translation = translation
                    self.explanation = explanation
                }
            },
            completion: { [weak self] error in
                Task { @MainActor in
                    guard let self else { return }
                    self.isStreaming = false
                    if let error {
                        if case .cancelled = error {
                            // 取消：保留已出内容，不报错
                        } else {
                            self.statusMessage = error.errorDescription
                        }
                        return
                    }
                    // 成功后记词
                    self.wordBook.record(word: text, translation: self.translation)
                }
            }
        )
    }

    func cancel() {
        client.cancel()
        isStreaming = false
    }
}