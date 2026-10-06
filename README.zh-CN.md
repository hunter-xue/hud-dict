# HudDict

[English](README.md) | **简体中文**

macOS 菜单栏悬浮词典。热键或菜单栏图标呼出小窗，输入一个词、一句话或一小段文字，回车后流式返回**译文**和**简短讲解**；查过的单词记入本地单词本。

它**不是**划词工具，也不是屏幕翻译：不读选区、不识屏、不申请辅助功能或录屏权限。

> **关于本项目**：这是一个 **vibe coding** 的成果。作者本人对 macOS、Swift、Xcode 开发**完全陌生**（正在尝试学习中），功能设计、架构决策与审校由人完成，绝大部分代码由 AI 生成。请据此评估其质量与适用性。

## 功能

### 悬浮小窗

- 菜单栏图标或全局热键呼出（默认 **⌘⌥⇧D**，可在设置中改）。
- 始终在其他窗口之上，跟随所有桌面，可盖住无边框全屏窗口。
- 半透明、可调透明度、可拖动；拖动条在窗口顶部。
- 呼出时**不抢占前台**：原应用仍是前台，菜单栏不切换、Dock 不跳。小窗可以接收键盘输入。
- 呼出即清空上次内容，作为一次全新查询；Esc 或再次点击菜单栏图标隐藏（不退出进程）。

### 查询与输出

- 输入任意短文本（一个词、一句、一小段）。
- 固定两段输出：**译文**，然后**简短讲解**（含词性/句式、当前语境含义、一条用法或易混点）。
- 流式显示，先出译文、讲解接着出；提交中可取消（取消保留已出内容）。
- 语言方向自动判断，目标语言默认简体中文，可在设置中改（译文与讲解共用这一栏）。
- 失败（断网、密钥错误、接口报错）在小窗内显示原因，不弹系统告警。

### LLM 设置

- 只支持 OpenAI 兼容的 Chat Completions 接口，用户自配：
  - **Base URL**（如 `https://api.openai.com`，程序请求 `{Base URL}/v1/chat/completions`，末尾 `/` 或 `/v1` 会自动规范化）
  - **模型名**
  - **API Key**（存 Keychain；界面只显示"已保存/未保存"，不明文回显；留空保存表示沿用旧密钥，另有"清除"按钮）
- 三项缺一不可，未配置完整时**不发请求**，小窗提示先完成设置。
- 保存前可发一次短请求做**连通测试**，失败原因显示在设置页。

因此 xAI、DeepSeek、Ollama、LM Studio 等兼容该路径的服务都能用。Anthropic / Gemini 原生接口、OpenAI Responses API 本版不支持。

### 单词本

- 仅在**查询成功后**记入；失败的查询不计数。
- 只记**单词**，不记短语或整句：判定为收尾修剪后不含空白、长度有限（拉丁 ≤ 40 / CJK ≤ 20 字符）、无句末标点。
- 同一词合并为一条：拉丁字母大小写不敏感（`Word` == `word`），中文/日文按原文合并。
- 每条存：词面、计数、最近查询时间、最近译文（不存讲解）。
- 独立窗口查看：默认计数降序、同计数按最近查询时间降序；可按键过滤、删除单条。
- 可导出 Markdown（词、计数、最近查询时间、最近译文），由用户选保存位置。
- 存本机 Application Support 目录（JSON），不上传、不同步。

### 设置项

LLM 设置、热键、目标语言、透明度、单词本、退出。

## 环境要求

- macOS 14 及以上
- 完整 Xcode（仅 Command Line Tools 不够）
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)：`brew install xcodegen`（用于生成工程）

## 构建与运行

Xcode 工程由 `project.yml` 生成，**不提交** `HudDict.xcodeproj`：

```sh
make generate   # 从 project.yml 生成 HudDict.xcodeproj
make build      # xcodebuild Debug 构建（产物在 DerivedData）
make run        # 用 swiftc 直接编译并运行（不依赖 xcodebuild）
```

也可以在 `make generate` 后用 Xcode 打开 `HudDict.xcodeproj` 运行。

## 测试与校验

```sh
make test       # 纯逻辑单元测试：StreamSplitter / SSEDecoder / WordNormalizer / WordBook 等
make typecheck  # 全量 swiftc 类型检查
make layering   # 校验 ExplainClient / WordBook 未引用 AppKit
```

- 测试是手写的断言脚本（不依赖 XCTest），退出码 0 表示通过，可在没有 Xcode 的环境跑。
- 修改 `project.yml` 后务必重新 `make generate`，不要手改 `HudDict.xcodeproj`。

## 架构

严格分两层，窗口层不进业务层：

| 目录 | 职责 | AppKit |
|---|---|---|
| `HudDict/HUDPanel` | 悬浮面板：显示/隐藏/置顶/透明度/拖动/不激活 | 是 |
| `HudDict/ExplainClient` | 组提示词、流式请求、切分译文与讲解 | **否** |
| `HudDict/WordBook` | 记词、计数、最近时间、Markdown 字符串 | **否** |
| `HudDict/Settings` | 设置窗口、Keychain、UserDefaults、连通测试 | 是 |
| `HudDict/WordBookUI` | 单词本窗口、导出（`NSSavePanel`） | 是 |
| `HudDict/HotKey` | Carbon `RegisterEventHotKey` 全局热键 | 是 |
| `HudDict/App` | 入口、菜单栏、装配 | 是 |

**关键约束**：`ExplainClient` 与 `WordBook` 不得 `import AppKit`（用 `make layering` 兜底）。文件选择（`NSSavePanel`）属于窗口层，`WordBook` 只产出 Markdown **字符串**。

### 代码入口

- 程序入口是 `HudDict/App/main.swift`（顶层代码必须放在名为 `main.swift` 的文件中），启动包在 `MainActor.assumeIsolated` 里。
- 悬浮面板的拖动由 AppKit 的 `WindowDragStrip` 叠加层处理（SwiftUI 内容会吃掉鼠标事件，不能只靠 `isMovableByWindowBackground`）。

### 流式输出协议

模型被要求按 `译文 <<<SPLIT>>> 讲解` 输出，客户端用 `StreamSplitter` 增量切分：
- 命中标记前的内容是译文，之后是讲解；
- 整段无标记时降级为"全部当译文、讲解留空"（`missingMarker == true`），不崩、不误切。

## 设计文档

- `docs/macos-hud-dictionary-requirements.md` — 需求说明
- `docs/macos-hud-dictionary-implementation-decisions.md` — 实现决策记录
- `AGENTS.md` — 给 AI 协作者的仓库速览与硬性约束

## 明确不做

划词/选区抓取/Accessibility、截图/OCR/录屏、点击穿透、剪贴板监听、系统离线词典、复习/背单词/熟悉度、句子级查询历史、非 `v1/chat/completions` 协议、Windows/Linux/移动端、自建后端。

## License

本项目采用 **Artisanal AI Slop License (AASL) v1.0** —— 一份面向"人类监督 + AI 生成"共同创作的开源许可证：系统设计、架构与审校由人类架构师完成，绝大部分代码 token 由 AI 合成。可自由使用、修改、分发（包括把代码投喂给其他 LLM），唯一条件是**保留原始仓库链接与作者/架构师署名**。

完整的中英双语许可证文本见 [`LICENSE`](LICENSE)。

本项目不接受 Pull Request；但欢迎通过 Issue 讨论与提出建议。
