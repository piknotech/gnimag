import Foundation
import Image
import ImageAnalysisKit
import TestingTools
import MrFlap
import Geometry

// let provider = ImageListProvider(directoryPath: "/Users/David/Desktop/ /gnimag-test/TestRun Hard", framerate: 30, imageFromCGImage: NativeImage.init)

let provider = AppWindowScreenProvider(appName: "AirServer", windowNameHint: "iPhone")
let tapper = NoopTapper()
let mrflap = MrFlap(imageProvider: provider, tapper: tapper, debugParameters: .init(location: "/Users/David/Desktop/Debug.noSync", severity: .onErrors))
mrflap.play()

RunLoop.main.run()
