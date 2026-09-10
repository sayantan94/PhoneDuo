import AppKit

// Read-only comparison of simulator screenshots. Run after capturing Docs/{neutral,left,right}.png.
let names = ["neutral", "left", "right"]
let images = try names.map { name -> NSBitmapImageRep in
    guard let bitmap = NSBitmapImageRep(data: try Data(contentsOf: URL(fileURLWithPath: "Docs/\(name).png"))) else {
        throw NSError(domain: "PhoneDuo.VisualCheck", code: 1)
    }
    return bitmap
}
for (a,b) in [(0,1),(0,2),(1,2)] {
    let width = images[a].pixelsWide, height = images[a].pixelsHigh
    precondition(width == images[b].pixelsWide && height == images[b].pixelsHigh)
    var difference = 0.0
    var count = 0
    // Exclude the system status area and fixed bottom control strip.
    for y in stride(from: height / 10, to: height * 85 / 100, by: 12) {
        for x in stride(from: 0, to: width, by: 12) {
            let first = images[a].colorAt(x: x, y: y)!.usingColorSpace(.deviceRGB)!
            let second = images[b].colorAt(x: x, y: y)!.usingColorSpace(.deviceRGB)!
            difference += abs(first.redComponent-second.redComponent)
                + abs(first.greenComponent-second.greenComponent)
                + abs(first.blueComponent-second.blueComponent)
            count += 3
        }
    }
    let mean = difference / Double(count) * 255
    guard mean > 5 else { fatalError("\(names[a]) and \(names[b]) did not visibly differ") }
    print("PASS \(names[a]) vs \(names[b]): mean RGB difference \(String(format: "%.2f", mean))/255")
}
