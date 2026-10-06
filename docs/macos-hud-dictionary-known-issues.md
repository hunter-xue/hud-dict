# macOS 悬浮词典 — 已知问题记录

状态：记录已发现但**暂不修复**的问题，供后续处理。按发现时间倒序。

---

## 1. 设置窗口粘贴快捷键失效（⌘V 等编辑快捷键无效）

### 现象

- 设置窗口打开、焦点在 Base URL 等输入框时，按 **⌘V 无反应**。
- 右键输入框能弹出上下文菜单，点"粘贴"**可以**正常粘贴。

### 影响范围

- 设置窗口的文本框。
- 由于同一根因，悬浮小窗与单词本窗口的文本框**可能同样受影响**。

### 根因

编辑快捷键（⌘V / ⌘C / ⌘X / ⌘A / ⌘Z）在 macOS 上**不是由文本框自己处理**的，而是由 **`NSApp.mainMenu` 的 Edit 菜单项**分发：

```
按 ⌘V → AppKit 在 mainMenu 中查找快捷键为 V 的菜单项 → 发给 First Responder（当前焦点控件）
```

本项目是 `LSUIElement`（`.accessory`）菜单栏应用，**没有 mainMenu**，也没有 Edit 菜单，因此 ⌘V 无处可查，直接失效。

右键能粘贴说明：输入框本身正常、剪贴板正常，问题**仅在于命令路由缺失**，不是输入被禁用。

### 相关代码

- `HudDict/App/main.swift`：`app.setActivationPolicy(.accessory)`，无 `NSApp.mainMenu`。
- `HudDict/App/AppDelegate.swift`：`showMenu()` 使用临时 `NSMenu`（`statusItem.menu = menu` 后立刻 `= nil`），菜单项未接入主菜单命令路由。

### 修复方案（已评估，暂不实施）

**方案 A（推荐）**：在启动时给 `NSApp.mainMenu` 装一个隐形的 Edit 子菜单，菜单项 target 留空走响应链：

| 菜单项 | 快捷键 | Selector |
|---|---|---|
| Undo | ⌘Z | `undo:` |
| Redo | ⇧⌘Z | `redo:` |
| Cut | ⌘X | `cut:` |
| Copy | ⌘C | `copy:` |
| Paste | ⌘V | `paste:` |
| Select All | ⌘A | `selectAll:` |

- `.accessory` app 设了 `mainMenu` 通常仍不显示菜单栏（先按此实现，若冒出菜单栏再加抑制手段）。
- 该方案自动覆盖三个窗口（悬浮小窗、设置窗口、单词本窗口）。

**方案 B**：为每个窗口单独挂载编辑命令（繁琐、易漏，不推荐）。
**方案 C**：仅处理悬浮面板（覆盖不全，不推荐）。

### 当前状态

**暂不修复**。用户选择了记录待办、保持现状。

---

## 2. 菜单栏图标与 App 图标不是同一张图（设计如此）

### 现象

菜单栏上显示的图标与 `Assets/AppIcon-source-1024.png`（App 图标）不同，看着像一本系统符号书本。

### 说明

**这不是 bug，是 macOS 的设计约束**：App 图标与菜单栏图标是两种东西。

| | App 图标 | 菜单栏图标 |
|---|---|---|
| 位置 | Dock / 访达 / DMG | 屏幕顶部菜单栏 |
| 当前实现 | `Assets/AppIcon-source-1024.png` 生成的 AppIcon | SF Symbol `character.book.closed` |
| 要求 | 彩色、圆角方图 | **单色模板图**（`isTemplate`），系统按主题自动反色 |

菜单栏图标必须做成"模板图"，且高度仅约 22pt。用户提供的图细节多、为彩色发光书本，缩到 22pt 会糊成一团、彩色也不生效。因此选择了系统 SF Symbol。

### 相关代码

- `HudDict/App/AppDelegate.swift` 的 `setupStatusItem()`：
  `statusItem.button?.image = NSImage(systemSymbolName: "character.book.closed", accessibilityDescription: "HudDict")`

### 备选（若将来想换成自定义图）

把源图转成模板剪影（取轮廓 → 去色 → 纯黑 + 透明 → 缩到 22pt）并在代码里设 `isTemplate = true`。**代价**：丢失发光与细节，仅剩轮廓，清晰度大概率不如 SF Symbol。

### 当前状态

**保持现状**。用户确认当前 SF Symbol 效果可接受。