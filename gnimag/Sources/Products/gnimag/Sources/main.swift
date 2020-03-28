import Common
import Foundation
import Image
import ImageAnalysisKit
import TestingTools
import MrFlap
import identiti
import Geometry
import Tapping

//let provider = AppWindowScreenProvider(appName: "AirServer", windowNameHint: "iPhone")
//let provider = ImageListProvider(directoryPath: "/Users/David/Desktop/ /identiti/Test-iOS", framerate: 30)

struct TTapper: ArbitraryLocationTapper {
    func tap(at point: CGPoint) {
        if point.x < 0.5 {
            print("LEFT")
        } else {
            print("RIGHT")
        }
    }
}

let id = identiti(imageProvider: Scrcpy.imageProvider, tapper: Scrcpy.tapper, os: .android)
Timing.perform(after: 1) {
    id.play()
}

RunLoop.main.run()
