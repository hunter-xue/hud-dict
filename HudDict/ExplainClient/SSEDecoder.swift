import Foundation

/// 解析 OpenAI 兼容接口的 SSE 流：只认 `data:` 行与结束标记 `[DONE]`。
public struct SSEDecoder {
    private var buffer = ""

    public init() {}

    public enum Event: Equatable {
        /// 一条 `data:` 行的负载（原始 JSON 字符串）。
        case data(String)
        /// 收到 `[DONE]`。
        case done
    }

    /// 喂入原始字节/字符串，返回本次可解析出的事件。
    public mutating func feed(_ text: String) -> [Event] {
        buffer += text
        var events: [Event] = []

        while let newlineRange = buffer.range(of: "\n") {
            let rawLine = String(buffer[..<newlineRange.lowerBound])
            buffer = String(buffer[newlineRange.upperBound...])
            let line = rawLine.hasSuffix("\r") ? String(rawLine.dropLast()) : rawLine
            if let event = parse(line: line) {
                events.append(event)
            }
        }
        return events
    }

    private func parse(line: String) -> Event? {
        guard line.hasPrefix("data:") else { return nil }
        var payload = String(line.dropFirst("data:".count))
        if payload.hasPrefix(" ") { payload.removeFirst() }
        if payload == "[DONE]" { return .done }
        return .data(payload)
    }
}

/// 从 Chat Completions 的流式 chunk JSON 中取出增量文本。
public enum ChatCompletionChunk {
    public static func deltaText(from json: String) -> String? {
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = object["choices"] as? [[String: Any]],
              let first = choices.first,
              let delta = first["delta"] as? [String: Any],
              let content = delta["content"] as? String
        else { return nil }
        return content
    }

    /// 非流式响应的正文。
    public static func messageText(from json: String) -> String? {
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = object["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String
        else { return nil }
        return content
    }

    /// 尽量从错误响应里取出一条人类可读信息。
    public static func errorMessage(from json: String) -> String? {
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        if let error = object["error"] as? [String: Any],
           let message = error["message"] as? String {
            return message
        }
        return object["message"] as? String
    }
}