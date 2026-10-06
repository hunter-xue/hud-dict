import Foundation

/// 把流式文本按分隔标记增量切分为「译文」和「讲解」两段。
///
/// 约定：模型输出形如 `译文内容\n<<<SPLIT>>>\n讲解内容`。
/// 命中分隔标记前的内容属于译文，之后属于讲解。
/// 若整段结束仍未出现标记，则全部当作译文（降级，不崩、不误切）。
public struct StreamSplitter {
    public static let marker = "<<<SPLIT>>>"

    public private(set) var translation: String = ""
    public private(set) var explanation: String = ""
    /// 结束前始终未出现分隔标记时为 true。
    public private(set) var missingMarker: Bool = false

    private var pending: String = ""
    private var splitFound = false
    private var finished = false

    public init() {}

    /// 追加一段流式文本，返回本段是否改变了任一输出段。
    @discardableResult
    public mutating func append(_ chunk: String) -> Bool {
        guard !chunk.isEmpty, !finished else { return false }
        pending += chunk

        if !splitFound {
            if let range = pending.range(of: Self.marker) {
                // 标记之前全部为译文（去掉紧邻标记的换行/空白）
                translation += String(pending[..<range.lowerBound]).trimmingTrailingNewlines()
                // 标记之后为讲解（去掉紧邻标记的换行/空白）
                explanation += String(pending[range.upperBound...]).trimmingLeadingNewlines()
                pending = ""
                splitFound = true
                return true
            }

            // 尚未命中标记：只把确定不含标记前缀的部分吐给译文，
            // 末尾保留可能构成标记前缀的字符，避免把标记切碎后误显示。
            flushSafePrefix()
            return true
        } else {
            explanation += pending
            pending = ""
            return true
        }
    }

    /// 流结束。若始终未命中标记则降级：全部内容当作译文。
    public mutating func finish() {
        guard !finished else { return }
        finished = true
        if !splitFound {
            translation += pending
            missingMarker = true
            pending = ""
        } else if !pending.isEmpty {
            explanation += pending
            pending = ""
        }
    }

    /// 把 pending 中「绝不可能是分隔标记一部分」的前缀刷入译文。
    private mutating func flushSafePrefix() {
        let markerCount = Self.marker.count
        guard pending.count > markerCount else { return }
        // 保留末尾 markerCount 个字符，其余可安全输出。
        let safeEnd = pending.index(pending.endIndex, offsetBy: -markerCount)
        translation += String(pending[..<safeEnd])
        pending = String(pending[safeEnd...])
    }
}

private extension String {
    func trimmingTrailingNewlines() -> String {
        var s = self
        while let last = s.last, last == "\n" || last == "\r" || last == " " {
            s.removeLast()
        }
        return s
    }

    func trimmingLeadingNewlines() -> String {
        var s = self
        while let first = s.first, first == "\n" || first == "\r" || first == " " {
            s.removeFirst()
        }
        return s
    }
}