import Foundation

/// 生成 Markdown 字符串（不写文件、不引用 AppKit）。文件选择与写入由窗口层负责。
public enum MarkdownExporter {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    public static func render(_ entries: [WordEntry]) -> String {
        var out = "# 单词本\n\n"
        for entry in entries {
            out += "## \(entry.surface)\n\n"
            out += "- 计数：\(entry.count)\n"
            out += "- 最近查询：\(formatter.string(from: entry.lastQueriedAt))\n"
            out += "- 最近译文：\(entry.lastTranslation)\n\n"
        }
        return out
    }
}