import Common
import Foundation
import Image
import ImageAnalysisKit
import TestingTools
import MrFlap
import identiti
import FlowFree
import Geometry
import Tapping

//let provider = AppWindowScreenProvider(appName: "AirServer", windowNameHint: "iPhone")
let provider = ImageListProvider(directoryPath: "/Users/David/Desktop/ /Flow-Free", framerate: 30)

let flow = FlowFreeSingleLevel(imageProvider: provider)
flow.play()

RunLoop.main.run()
