import Foundation
import Image
import ImageAnalysisKit
import MacTestingTools
import MrFlap
import Geometry

let p = Geometry.Polygon(points: [CGPoint(x: 10, y: 10), CGPoint(x: 20, y: 30), CGPoint(x: 80, y: 30), CGPoint(x: 60, y: 60), CGPoint(x: 50, y: 60), CGPoint(x: 50, y: 10)])
let oobb = SmallestOBB.containing(p.points)
let b = AABB(center: CGPoint(x: 30, y: 30), width: 40, height: 40)
BitmapCanvas(width: 100, height: 100).fillWithRandomColorPattern(alpha: 0.3).fill(p, with: .white).stroke(p, with: .red, strokeWidth: 2).stroke(oobb, with: .blue).write(to: "/Users/David/Desktop/a.png")

let provider = ImageListProvider(directoryPath: "/Users/David/Desktop/Fun/gnimag-test/TestRun", framerate: 1, imageFromCGImage: NativeImage.init)
let tapper = NoopTapper()
let mrflap = MrFlap(imageProvider: provider, tapper: tapper)
mrflap.play()

RunLoop.main.run()
