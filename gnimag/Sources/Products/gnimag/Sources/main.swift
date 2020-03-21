import Foundation
import Image
import ImageAnalysisKit
import TestingTools
import MrFlap
import identiti
import Geometry

let provider = ImageListProvider(directoryPath: "/Users/David/Desktop/ /identiti/Test-iOS", framerate: 30, imageFromCGImage: NativeImage.init)

let id = identiti(imageProvider: provider, tapper: NoopTapper())
id.play()

RunLoop.main.run()
