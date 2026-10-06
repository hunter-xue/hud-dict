import Foundation

/// 组装发给模型的提示词，约定输出为「译文 + 分隔标记 + 讲解」两段。
public enum PromptBuilder {
    public static func systemPrompt(targetLanguage: String) -> String {
        """
        你是一个词典助手。用户会给你一个词、一句话或一小段文本。
        你必须输出两段内容，中间用单独一行的标记 \(StreamSplitter.marker) 分隔：

        第一段：译文。把用户输入翻译成\(targetLanguage)。
        第二段：简短讲解。用\(targetLanguage)写，包含：词性或句式、在当前语境下的含义、一条用法或易混点。

        要求：
        - 严格先译文后讲解，两段之间只放那一行标记，不要任何其他分隔或标题。
        - 讲解要简短，不要长篇大论。
        - 不要输出 Markdown 代码块，不要加多余的说明或客套话。
        """
    }

    public static func userPrompt(_ input: String) -> String {
        input
    }
}