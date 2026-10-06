import Foundation

/// LLM 设置（不含密钥；密钥单独走 Keychain）。
public struct LLMSettings: Equatable, Sendable {
    public var baseURL: String
    public var model: String

    public init(baseURL: String = "", model: String = "") {
        self.baseURL = baseURL
        self.model = model
    }

    /// 规范化 Base URL：去掉末尾的 `/`，并去掉末尾的 `/v1`，避免拼成 `/v1/v1`。
    public static func normalizeBaseURL(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        while s.hasSuffix("/") { s.removeLast() }
        if s.hasSuffix("/v1") { s.removeLast(3) }
        while s.hasSuffix("/") { s.removeLast() }
        return s
    }

    public func chatCompletionsURL() -> URL? {
        let base = Self.normalizeBaseURL(baseURL)
        guard !base.isEmpty else { return nil }
        return URL(string: base + "/v1/chat/completions")
    }
}

public enum ExplainError: Error, LocalizedError {
    case notConfigured
    case invalidURL
    case http(status: Int, message: String?)
    case network(String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .notConfigured: return "请先在设置里完成 LLM 配置。"
        case .invalidURL: return "Base URL 无效。"
        case let .http(status, message):
            if let message, !message.isEmpty { return "接口错误（\(status)）：\(message)" }
            return "接口错误（\(status)）。"
        case let .network(text): return "网络错误：\(text)"
        case .cancelled: return "已取消。"
        }
    }
}

/// 流式查询 OpenAI 兼容接口，逐段回调译文/讲解内容。不引用 AppKit。
public final class ExplainClient {
    private let session: URLSession
    private var task: URLSessionDataTask?

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// 发起流式查询。
    /// - Parameters:
    ///   - onUpdate: 每次内容变化时回调当前译文与讲解。
    ///   - completion: 结束回调，成功为 nil，失败为错误。
    public func stream(
        input: String,
        settings: LLMSettings,
        apiKey: String,
        targetLanguage: String,
        onUpdate: @escaping (_ translation: String, _ explanation: String) -> Void,
        completion: @escaping (ExplainError?) -> Void
    ) {
        guard let url = settings.chatCompletionsURL(), !settings.model.isEmpty, !apiKey.isEmpty else {
            completion(.notConfigured)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": settings.model,
            "stream": true,
            "messages": [
                ["role": "system", "content": PromptBuilder.systemPrompt(targetLanguage: targetLanguage)],
                ["role": "user", "content": PromptBuilder.userPrompt(input)],
            ],
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        var splitter = StreamSplitter()
        var decoder = SSEDecoder()

        let task = session.dataTask(with: request) { [weak self] data, response, error in
            _ = self
            defer { self?.task = nil }

            if let error {
                let nsError = error as NSError
                if nsError.code == NSURLErrorCancelled {
                    completion(.cancelled)
                } else {
                    completion(.network(error.localizedDescription))
                }
                return
            }
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                let text = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                completion(.http(status: http.statusCode, message: ChatCompletionChunk.errorMessage(from: text)))
                return
            }

            let text = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            let events = decoder.feed(text)
            for event in events {
                switch event {
                case .done:
                    break
                case let .data(payload):
                    if let delta = ChatCompletionChunk.deltaText(from: payload) {
                        if splitter.append(delta) {
                            onUpdate(splitter.translation, splitter.explanation)
                        }
                    }
                }
            }
            splitter.finish()
            onUpdate(splitter.translation, splitter.explanation)
            completion(nil)
        }
        self.task = task
        task.resume()
    }

    public func cancel() {
        task?.cancel()
        task = nil
    }

    /// 连通测试用的非流式短请求。
    public func testConnection(
        settings: LLMSettings,
        apiKey: String,
        completion: @escaping (ExplainError?) -> Void
    ) {
        guard let url = settings.chatCompletionsURL(), !settings.model.isEmpty, !apiKey.isEmpty else {
            completion(.notConfigured)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "model": settings.model,
            "stream": false,
            "messages": [["role": "user", "content": "ping"]],
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        session.dataTask(with: request) { data, response, error in
            if let error {
                completion(.network(error.localizedDescription))
                return
            }
            guard let http = response as? HTTPURLResponse else {
                completion(.http(status: -1, message: nil))
                return
            }
            if (200...299).contains(http.statusCode) {
                completion(nil)
            } else {
                let text = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                completion(.http(status: http.statusCode, message: ChatCompletionChunk.errorMessage(from: text)))
            }
        }.resume()
    }
}