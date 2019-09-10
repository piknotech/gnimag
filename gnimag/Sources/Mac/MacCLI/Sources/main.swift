import Foundation
import Image
import ImageAnalysisKit
import MacTestingTools
import MrFlap
import Geometry

let provider = ImageListProvider(directoryPath: "/Users/David/Desktop/Fun/gnimag-test/TestRun", framerate: 1, imageFromCGImage: NativeImage.init)
let tapper = NoopTapper()
let mrflap = MrFlap(imageProvider: provider, tapper: tapper)
mrflap.play()

RunLoop.main.run()
