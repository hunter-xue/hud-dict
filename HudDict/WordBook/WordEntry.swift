import Foundation

/// 单词本条目。
public struct WordEntry: Codable, Equatable, Identifiable, Sendable {
    /// 合并键（唯一）。
    public let key: String
    /// 词面：展示用最近一次的写法。
    public var surface: String
    /// 计数：每成功查一次加一。
    public var count: Int
    /// 最近查询时间：覆盖，不保留历史。
    public var lastQueriedAt: Date
    /// 最近一次译文：不存讲解全文，不保留旧译文。
    public var lastTranslation: String

    public var id: String { key }

    public init(key: String, surface: String, count: Int, lastQueriedAt: Date, lastTranslation: String) {
        self.key = key
        self.surface = surface
        self.count = count
        self.lastQueriedAt = lastQueriedAt
        self.lastTranslation = lastTranslation
    }
}