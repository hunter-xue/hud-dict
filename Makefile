# HudDict 构建与测试快捷命令
#
# 说明：本项目用 XcodeGen 从 project.yml 生成 HudDict.xcodeproj，
# 不要把 HudDict.xcodeproj 当成手改对象——改结构请改 project.yml 后重新 generate。

PROJECT = HudDict.xcodeproj
SCHEME = HudDict
SDK = $(shell xcrun --show-sdk-path --sdk macosx)
TARGET = arm64-apple-macos14.0

PURE_SOURCES = \
	HudDict/ExplainClient/StreamSplitter.swift \
	HudDict/ExplainClient/SSEDecoder.swift \
	HudDict/ExplainClient/ExplainClient.swift \
	HudDict/ExplainClient/PromptBuilder.swift \
	HudDict/WordBook/WordNormalizer.swift \
	HudDict/WordBook/WordEntry.swift \
	HudDict/WordBook/WordBookStore.swift \
	HudDict/WordBook/WordBook.swift \
	HudDict/WordBook/MarkdownExporter.swift

.PHONY: generate build typecheck test layering run icon clean

## 从 project.yml 重新生成 Xcode 工程
generate:
	xcodegen generate

## 从 Assets/AppIcon-source-1024.png 重新生成 AppIcon 图标集
icon:
	./scripts/make_icon.sh

## 用 xcodebuild 构建（需要可用的完整 Xcode）
build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug build

## 不依赖 xcodebuild 的快速类型检查（本机 Xcode 插件异常时可用）
typecheck:
	swiftc -typecheck -target $(TARGET) -sdk "$(SDK)" $$(find HudDict -name '*.swift')

## 运行纯逻辑单元测试（无需 Xcode）
test:
	swiftc -target $(TARGET) -sdk "$(SDK)" -o .build/HudDictTests \
		Tests/HudDictTests/main.swift $(PURE_SOURCES)
	./.build/HudDictTests

## 校验分层：ExplainClient / WordBook 不得 import AppKit（应无输出）
layering:
	@! grep -rn "import AppKit" HudDict/ExplainClient HudDict/WordBook

## 编译出可执行文件并运行
run:
	swiftc -target $(TARGET) -sdk "$(SDK)" -o .build/HudDict $$(find HudDict -name '*.swift')
	./.build/HudDict

clean:
	rm -rf .build
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean 2>/dev/null || true