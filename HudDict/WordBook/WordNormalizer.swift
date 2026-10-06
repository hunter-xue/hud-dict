import Foundation

/// 判定一段输入是否算「单词」，并生成合并键。
public enum WordNormalizer {
    /// 拉丁字母词的长度上限。
    public static let latinMaxLength = 40
    /// CJK 词的长度上限。
    public static let cjkMaxLength = 20

    private static let sentenceEnders: Set<Character> = ["。", "！", "？", "!", "?", ".", "；", ";", "…"]

    /// 收尾空白修剪后的输入是否应记入单词本。
    public static func isRecordable(_ input: String) -> Bool {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        // 不含任何空白
        guard !trimmed.contains(where: { $0.isWhitespace }) else { return false }
        // 无句末标点
        guard !trimmed.contains(where: { sentenceEnders.contains($0) }) else { return false }
        // 长度有限
        let limit = containsCJK(trimmed) ? cjkMaxLength : latinMaxLength
        return trimmed.count <= limit
    }

    /// 合并键：拉丁字母大小写不敏感；CJK 按原文。
    public static func mergeKey(for input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if containsCJK(trimmed) { return trimmed }
        return trimmed.lowercased()
    }

    private static func containsCJK(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x4E00...0x9FFF,   // CJK 统一表意
                 0x3400...0x4DBF,   // 扩展 A
                 0x3040...0x30FF,   // 平假名 / 片假名
                 0xF900...0xFAFF:   // 兼容表意
                return true
            default:
                return false
            }
        }
    }
}