import AppKit
import CoreGraphics

// 读取源 PNG，裁剪为 macOS 圆角并输出透明外角的 1024 PNG。
// 背景本身是深色不透明，这里只负责把四个角切圆并让外侧透明，
// 使图标在 Dock / 访达中符合 macOS 惯例。

let inputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "dict_icon.png"
let outputPath = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "AppIcon-1024.png"

guard let source = NSImage(contentsOfFile: inputPath),
      let tiff = source.tiffRepresentation,
      let srcRep = NSBitmapImageRep(data: tiff) else {
    fatalError("无法读取输入图片：\(inputPath)")
}

let size = srcRep.pixelsWide
let height = srcRep.pixelsHigh
guard size == height else { fatalError("需要正方形图片，当前 \(size)x\(height)") }

// macOS 图标圆角半径：约画布的 22.37%
let cornerRadius = CGFloat(size) * 0.2237

// 目标位图（带 alpha）
guard let dstRep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: size,
    pixelsHigh: size,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else { fatalError("无法创建目标位图") }

guard let ctx = NSGraphicsContext(bitmapImageRep: dstRep) else { fatalError("无法创建绘图上下文") }
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = ctx

let rect = NSRect(x: 0, y: 0, width: size, height: size)
let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
path.addClip()
source.draw(in: rect, from: .zero, operation: .copy, fraction: 1.0)

NSGraphicsContext.restoreGraphicsState()

guard let pngData = dstRep.representation(using: .png, properties: [:]) else {
    fatalError("无法编码 PNG")
}
try pngData.write(to: URL(fileURLWithPath: outputPath))
print("已输出圆角图标：\(outputPath)（\(size)x\(size)，圆角半径 \(Int(cornerRadius))px）")