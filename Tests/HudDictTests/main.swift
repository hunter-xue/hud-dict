import Foundation

// 轻量测试：不依赖 XCTest，直接断言，便于在无 Xcode 环境下用 swiftc 运行。
var failures = 0
func expect(_ condition: Bool, _ message: String) {
    if condition {
        print("  ok: \(message)")
    } else {
        failures += 1
        print("  FAIL: \(message)")
    }
}

// MARK: - StreamSplitter

print("StreamSplitter")
do {
    var s = StreamSplitter()
    s.append("Hello")
    s.append(" world")
    s.append("\n<<<SPLIT>>>\n讲解内容")
    s.finish()
    expect(s.translation.contains("Hello world"), "译文按序拼接")
    expect(!s.translation.contains("<<<SPLIT>>>"), "译文不含标记")
    expect(s.explanation.contains("讲解内容"), "讲解在标记之后")
    expect(!s.missingMarker, "命中标记时 missingMarker=false")
}

do {
    // 标记被拆到多个 chunk
    var s = StreamSplitter()
    s.append("译文")
    s.append("\n<<<SP")
    s.append("LIT>>>")
    s.append("讲解")
    s.finish()
    expect(s.translation == "译文", "标记跨 chunk 时译文正确")
    expect(s.explanation == "讲解", "标记跨 chunk 时讲解正确")
}

do {
    // 无标记 → 降级全文作文译文
    var s = StreamSplitter()
    s.append("只有译文没有标记")
    s.finish()
    expect(s.translation == "只有译文没有标记", "无标记时全部当译文")
    expect(s.explanation.isEmpty, "无标记时讲解为空")
    expect(s.missingMarker, "无标记时 missingMarker=true")
}

// MARK: - SSEDecoder

print("SSEDecoder")
do {
    var d = SSEDecoder()
    let events = d.feed("data: {\"a\":1}\n\ndata: [DONE]\n\n")
    expect(events.count == 2, "解析出两个事件")
    expect(events.first == .data("{\"a\":1}"), "第一个是 data")
    expect(events.last == .done, "最后是 done")
}

do {
    // 分块到达
    var d = SSEDecoder()
    var got: [SSEDecoder.Event] = []
    got += d.feed("data: {\"a\"")
    got += d.feed(":1}\ndata: [DO")
    got += d.feed("NE]\n")
    expect(got == [.data("{\"a\":1}"), .done], "分块 SSE 正确重组")
}

// MARK: - LLMSettings.normalizeBaseURL

print("LLMSettings")
do {
    expect(LLMSettings.normalizeBaseURL("https://api.openai.com") == "https://api.openai.com", "无后缀不变")
    expect(LLMSettings.normalizeBaseURL("https://api.openai.com/") == "https://api.openai.com", "去末尾斜杠")
    expect(LLMSettings.normalizeBaseURL("https://api.openai.com/v1") == "https://api.openai.com", "去 /v1")
    expect(LLMSettings.normalizeBaseURL("https://api.openai.com/v1/") == "https://api.openai.com", "去 /v1/")
    let url = LLMSettings(baseURL: "https://api.openai.com/v1", model: "m").chatCompletionsURL()?.absoluteString
    expect(url == "https://api.openai.com/v1/chat/completions", "拼出正确的请求 URL")
}

// MARK: - WordNormalizer

print("WordNormalizer")
do {
    expect(WordNormalizer.isRecordable("word"), "普通单词可记")
    expect(WordNormalizer.isRecordable("Hello"), "大写单词可记")
    expect(!WordNormalizer.isRecordable("hello world"), "含空格不记")
    expect(!WordNormalizer.isRecordable("How are you?"), "整句不记")
    expect(!WordNormalizer.isRecordable("今天天气很好。"), "中文整句（含句末标点）不记")
    expect(WordNormalizer.isRecordable("词"), "单个汉字可记")
    expect(!WordNormalizer.isRecordable("这是一个非常非常非常非常长的中文句子没有标点"), "超长中文不记")
    expect(WordNormalizer.mergeKey(for: "Word") == WordNormalizer.mergeKey(for: "word"), "拉丁大小写合并键相同")
    expect(WordNormalizer.mergeKey(for: "词") == "词", "中文合并键用原文")
}

// MARK: - WordBook

print("WordBook")
do {
    let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("huddict-test-\(UUID().uuidString).json")
    let store = WordBookStore(fileURL: tmp)
    let book = WordBook(store: store)

    let t1 = Date(timeIntervalSince1970: 1000)
    let t2 = Date(timeIntervalSince1970: 2000)
    book.record(word: "word", translation: "词", at: t1)
    book.record(word: "Word", translation: "单词", at: t2)

    let sorted = book.sorted()
    expect(sorted.count == 1, "大小写合并为一条")
    expect(sorted.first?.count == 2, "计数累加到 2")
    expect(sorted.first?.lastQueriedAt == t2, "最近时间覆盖为最新")
    expect(sorted.first?.lastTranslation == "单词", "最近译文覆盖")
    expect(sorted.first?.surface == "Word", "词面用最近写法")

    expect(book.record(word: "a whole sentence here", translation: "x") == false, "整句不记入")
    expect(book.record(word: "failed", translation: "") == true, "单词记入")

    // 排序：计数降序
    let ordered = book.sorted()
    expect(ordered.first?.surface == "Word", "计数高的排前面")

    // 过滤
    expect(book.sorted(filter: "wor").count == 1, "按词过滤")

    // 持久化往返
    let reloaded = WordBook(store: store)
    expect(reloaded.entries.count == 2, "重新加载后条目数一致")

    // 删除
    book.delete(key: WordNormalizer.mergeKey(for: "Word"))
    expect(book.sorted().count == 1, "删除单条生效")

    // Markdown
    let md = book.markdown()
    expect(md.contains("# 单词本"), "Markdown 有标题")
    expect(md.contains("计数"), "Markdown 含计数")

    try? FileManager.default.removeItem(at: tmp)
}

if failures == 0 {
    print("\nALL TESTS PASSED")
    exit(0)
} else {
    print("\n\(failures) TEST(S) FAILED")
    exit(1)
}