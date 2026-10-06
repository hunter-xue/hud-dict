import AppKit
import SwiftUI

/// 单词本窗口（独立普通窗口）。
public final class WordBookWindowController {
    private var window: NSWindow?
    private let wordBook: WordBook
    private let store: WordBookStore

    public init(wordBook: WordBook, store: WordBookStore) {
        self.wordBook = wordBook
        self.store = store
    }

    public func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let view = WordBookView(wordBook: wordBook)
        let hosting = NSHostingController(rootView: view)
        let win = NSWindow(contentViewController: hosting)
        win.title = "单词本"
        win.styleMask = [.titled, .closable, .resizable]
        win.setContentSize(NSSize(width: 480, height: 520))
        win.isReleasedWhenClosed = false
        win.center()
        window = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

/// 单词本界面：排序展示、按词过滤、删除、导出 Markdown。
struct WordBookView: View {
    @ObservedObject var wordBook: WordBookObserver

    init(wordBook: WordBook) {
        self.wordBook = WordBookObserver(wordBook: wordBook)
    }

    @State private var filter = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("按词过滤", text: $filter)
                    .textFieldStyle(.roundedBorder)
                Button("导出 Markdown") { export() }
            }
            .padding(10)

            List {
                ForEach(wordBook.sorted(filter: filter)) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(entry.surface).font(.system(size: 14, weight: .semibold))
                            Spacer()
                            Text("×\(entry.count)").foregroundStyle(.secondary)
                        }
                        Text(entry.lastTranslation)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .contextMenu {
                        Button("删除") { wordBook.delete(key: entry.key) }
                    }
                }
            }
        }
    }

    private func export() {
        let markdown = wordBook.markdown(filter: filter)
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "wordbook.md"
        panel.allowedContentTypes = [.init(filenameExtension: "md")].compactMap { $0 }
        if panel.runModal() == .OK, let url = panel.url {
            try? markdown.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

/// 让 SwiftUI 能观察 WordBook 变化。
final class WordBookObserver: ObservableObject {
    private let wordBook: WordBook
    @Published private(set) var revision = 0

    init(wordBook: WordBook) {
        self.wordBook = wordBook
    }

    func sorted(filter: String) -> [WordEntry] { wordBook.sorted(filter: filter) }

    func delete(key: String) {
        wordBook.delete(key: key)
        revision += 1
    }

    func markdown(filter: String) -> String { wordBook.markdown(filter: filter) }
}