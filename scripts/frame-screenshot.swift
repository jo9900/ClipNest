import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Export an actual window capture on an opaque 1280 × 800 App Store canvas.
guard CommandLine.arguments.count == 4,
      let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    fatalError("Usage: frame-screenshot input.png output.png light|dark")
}
let context = CGContext(data: nil, width: 1280, height: 800, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
context.setFillColor(CGColor(gray: CommandLine.arguments[3] == "dark" ? 0.10 : 0.94, alpha: 1))
context.fill(CGRect(x: 0, y: 0, width: 1280, height: 800))
let height = 560 * CGFloat(image.height) / CGFloat(image.width)
context.interpolationQuality = .high
context.draw(image, in: CGRect(x: 360, y: (800 - height) / 2, width: 560, height: height))
let output = CGImageDestinationCreateWithURL(URL(fileURLWithPath: CommandLine.arguments[2]) as CFURL,
                                            UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(output, context.makeImage()!, nil)
guard CGImageDestinationFinalize(output) else { fatalError("Could not save screenshot") }
