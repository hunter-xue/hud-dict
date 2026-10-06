# HudDict

macOS 菜单栏悬浮词典。热键或菜单栏图标呼出小窗，输入词/句/段落，流式返回译文和简短讲解；查过的单词记入本地单词本。

需求与实现决策见 `docs/`：
- `docs/macos-hud-dictionary-requirements.md` — 需求说明
- `docs/macos-hud-dictionary-implementation-decisions.md` — 实现决策记录

## 环境要求

- macOS 14+
- 完整 Xcode（Command Line Tools 不够）
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)：`brew install xcodegen`

## 构建 / 运行

Xcode 工程由 `project.yml` 生成，**不提交** `HudDict.xcodeproj`：

```sh
make generate   # 生成 HudDict.xcodeproj
make build      # xcodebuild Debug 构建
make run        # swiftc 编译并直接运行
```

## 测试

纯逻辑单元测试（无需 Xcode）：

```sh
make test       # StreamSplitter / SSEDecoder / WordNormalizer / WordBook 等
make typecheck  # 全量类型检查
make layering   # 校验 ExplainClient / WordBook 不引用 AppKit
```

## 架构

- `HUDPanel` — AppKit 悬浮面板（不抢前台、置顶、可拖、透明度）
- `ExplainClient` — 流式请求与译文/讲解切分（**不引用 AppKit**）
- `WordBook` — 单词本记录与 Markdown 导出（**不引用 AppKit**）
- `Settings` / `WordBookUI` / `HotKey` / `App` — 窗口与胶水层