import Foundation

/// 单词本核心逻辑：记词、合并、排序、过滤、删除、导出字符串。不引用 AppKit。
public final class WordBook {
    private let store: WordBookStore
    private(set) public var entries: [WordEntry]

    /// 写盘失败时的回调，供上层提示；不静默丢失。
    public var onSaveError: ((Error) -> Void)?

    public init(store: WordBookStore = WordBookStore()) {
        self.store = store
        self.entries = store.load()
    }

    /// 查询成功后调用。仅在可记入时生效。
    @discardableResult
    public func record(word: String, translation: String, at date: Date = Date()) -> Bool {
        guard WordNormalizer.isRecordable(word) else { return false }
        let key = WordNormalizer.mergeKey(for: word)
        let surface = word.trimmingCharacters(in: .whitespacesAndNewlines)

        if let index = entries.firstIndex(where: { $0.key == key }) {
            entries[index].count += 1
            entries[index].lastQueriedAt = date
            entries[index].lastTranslation = translation
            entries[index].surface = surface
        } else {
            entries.append(WordEntry(key: key, surface: surface, count: 1, lastQueriedAt: date, lastTranslation: translation))
        }
        persist()
        return true
    }

    public func delete(key: String) {
        entries.removeAll { $0.key == key }
        persist()
    }

    /// 排序：计数降序，计数相同按最近查询时间降序。filter 为空则不过滤。
    public func sorted(filter: String = "") -> [WordEntry] {
        let needle = filter.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered = needle.isEmpty
            ? entries
            : entries.filter { $0.surface.lowercased().contains(needle) }
        return filtered.sorted {
            if $0.count != $1.count { return $0.count > $1.count }
            return $0.lastQueriedAt > $1.lastQueriedAt
        }
    }

    /// 按当前排序生成 Markdown 字符串（不写文件）。
    public func markdown(filter: String = "") -> String {
        MarkdownExporter.render(sorted(filter: filter))
    }

    private func persist() {
        do {
            try store.save(entries)
        } catch {
            onSaveError?(error)
        }
    }
}