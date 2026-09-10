import AppKit
let size = 1024
let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size*4,
    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
context.setFillColor(CGColor(red: 0.10, green: 0.19, blue: 0.19, alpha: 1))
context.fill(CGRect(x: 0, y: 0, width: size, height: size))
func pane(_ points: [CGPoint], _ color: CGColor) {
    context.beginPath(); context.move(to: points[0])
    points.dropFirst().forEach { context.addLine(to: $0) }; context.closePath()
    context.setFillColor(color); context.fillPath()
}
pane([CGPoint(x: 235,y: 260),CGPoint(x: 499,y: 195),CGPoint(x: 499,y: 735),CGPoint(x: 235,y: 790)], CGColor(red: 0.54,green: 0.75,blue: 0.64,alpha: 1))
pane([CGPoint(x: 525,y: 195),CGPoint(x: 790,y: 320),CGPoint(x: 790,y: 850),CGPoint(x: 525,y: 735)], CGColor(red: 0.85,green: 0.95,blue: 0.86,alpha: 1))
context.setStrokeColor(CGColor(red: 0.98,green: 1,blue: 0.96,alpha: 0.65))
context.setLineWidth(8)
context.move(to: CGPoint(x: 265,y: 740)); context.addLine(to: CGPoint(x: 460,y: 700)); context.strokePath()
let image = context.makeImage()!
let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
try data.write(to: URL(fileURLWithPath: "PhoneDuo/Assets.xcassets/AppIcon.appiconset/AppIcon.png"))
