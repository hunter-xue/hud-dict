import SwiftUI

/// 主面板 SwiftUI 内容。
public struct PanelView: View {
    @ObservedObject var model: PanelModel
    @FocusState private var inputFocused: Bool

    public init(model: PanelModel) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 顶部留给 AppKit 的 WindowDragStrip（它自绘手柄）；这里只留出空间。
            Color.clear.frame(height: WindowDragStrip.height - 12)

            TextField("输入一个词、一句话或一小段，回车查询", text: $model.input)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(Self.bodyText)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08)))
                .frame(maxWidth: .infinity, alignment: .leading)
                .focused($inputFocused)
                .onSubmit { model.submit() }
                .onChange(of: model.focusRequest) { _, _ in inputFocused = true }

            if !model.translation.isEmpty || !model.explanation.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        if !model.translation.isEmpty {
                            section(title: "译文", text: model.translation)
                        }
                        if !model.explanation.isEmpty {
                            section(title: "讲解", text: model.explanation)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            if let status = model.statusMessage {
                Text(status)
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            HStack {
                if model.isStreaming {
                    ProgressView().controlSize(.small)
                    Button("取消") { model.cancel() }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                }
            }
            .font(.system(size: 12))
        }
        .padding(14)
        // 固定深色底 + 圆角卡片，避免屏幕背景为浅色时文字对比度不足。
        // 背景/描边层不参与命中，否则会挡掉面板顶部拖动条的事件。
        .background(
            RoundedRectangle(cornerRadius: Self.cornerRadius)
                .fill(Self.panelBackground)
                .allowsHitTesting(false)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Self.cornerRadius)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                .allowsHitTesting(false)
        )
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
        // 强制深色外观，使输入框、进度条、按钮等控件配色一致。
        .environment(\.colorScheme, .dark)
        .frame(width: 420, height: 300)
        .onAppear { inputFocused = true }
    }

    /// 面板固定深色底。
    private static let panelBackground = Color(white: 0.12)
    /// 正文文字（近白）。
    private static let bodyText = Color.white.opacity(0.92)
    /// 卡片圆角。
    private static let cornerRadius: CGFloat = 12

    @ViewBuilder
    private func section(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Self.bodyText)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}