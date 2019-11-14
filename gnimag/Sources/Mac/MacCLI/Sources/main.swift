import Foundation
import Image
import ImageAnalysisKit
import MacTestingTools
import MrFlap
import Geometry

let provider = ImageListProvider(directoryPath: "/Users/David/Desktop/Fun/gnimag-test/TestRun", framerate: 30, imageFromCGImage: NativeImage.init)
let tapper = NoopTapper()
let mrflap = MrFlap(imageProvider: provider, tapper: tapper, debugParameters: DebugParameters(location: "/Users/David/Desktop/Debug.nosync", severity: .alwaysText))
mrflap.play()

RunLoop.main.run()
