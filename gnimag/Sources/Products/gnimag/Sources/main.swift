import Foundation
import Image
import ImageAnalysisKit
import TestingTools
import MrFlap
import identiti
import Geometry

let provider = AppWindowScreenProvider(appName: "AirServer", windowNameHint: "iPhone")
//let provider = ImageListProvider(directoryPath: "/Users/David/Desktop/Test", framerate: 30, imageFromCGImage: NativeImage.init)

let id = identiti(imageProvider: provider, tapper: WindowTapper(appName: "AirServer", windowNameHint: "i"))
id.play()

RunLoop.main.run()
