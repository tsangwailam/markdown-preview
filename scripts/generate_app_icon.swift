import AppKit

let outPath = CommandLine.arguments.dropFirst().first ?? "icon_1024.png"
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()
if let ctx = NSGraphicsContext.current?.cgContext {
    ctx.setAllowsAntialiasing(true)

    let rect = CGRect(origin: .zero, size: size)
    let bgPath = NSBezierPath(roundedRect: rect.insetBy(dx: 40, dy: 40), xRadius: 220, yRadius: 220)

    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.13, green: 0.28, blue: 0.47, alpha: 1.0),
        NSColor(calibratedRed: 0.07, green: 0.11, blue: 0.22, alpha: 1.0)
    ])!
    gradient.draw(in: bgPath, angle: -45)

    let paperRect = CGRect(x: 240, y: 200, width: 540, height: 650)
    let paper = NSBezierPath(roundedRect: paperRect, xRadius: 36, yRadius: 36)
    NSColor(calibratedWhite: 0.98, alpha: 1.0).setFill()
    paper.fill()

    let fold = NSBezierPath()
    fold.move(to: CGPoint(x: 675, y: 850))
    fold.line(to: CGPoint(x: 780, y: 745))
    fold.line(to: CGPoint(x: 675, y: 745))
    fold.close()
    NSColor(calibratedWhite: 0.90, alpha: 1.0).setFill()
    fold.fill()

    let md = NSString(string: "MD")
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 210, weight: .bold),
        .foregroundColor: NSColor(calibratedRed: 0.10, green: 0.27, blue: 0.56, alpha: 1.0)
    ]
    let mdSize = md.size(withAttributes: attrs)
    let mdRect = CGRect(x: paperRect.midX - mdSize.width / 2, y: paperRect.midY - mdSize.height / 2 - 40, width: mdSize.width, height: mdSize.height)
    md.draw(in: mdRect, withAttributes: attrs)

    let lineColor = NSColor(calibratedWhite: 0.84, alpha: 1.0)
    lineColor.setStroke()
    for i in 0..<3 {
        let y = paperRect.minY + 120 + CGFloat(i) * 64
        let p = NSBezierPath()
        p.move(to: CGPoint(x: paperRect.minX + 70, y: y))
        p.line(to: CGPoint(x: paperRect.maxX - 70, y: y))
        p.lineWidth = 10
        p.stroke()
    }
}
image.unlockFocus()

let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
let data = rep.representation(using: .png, properties: [:])!
try data.write(to: URL(fileURLWithPath: outPath))
print("Wrote \(outPath)")
