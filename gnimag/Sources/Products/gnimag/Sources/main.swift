import Common
import Foundation
import QuartzCore
import Image
import ImageAnalysisKit
import TestingTools
import GameKit
import MrFlap
import YesNoMathGames
import FlowFree
import Geometry
import Tapping

/*
let drag = identiti(imageProvider: scrcpy.imageProvider, tapper: scrcpy.tapper, os: .android)
drag.play()
RunLoop.main.run()
*/

// let a = ScreenInteractor(frame: CGRect(x: 529, y: 227, width: 388, height: 390))
// let a = ImageListProvider(directoryPath: "/Users/David/Desktop/I", framerate: 50)
let game = MrFlapGameSimulation(fps: 50)

let t = T()
let tapper = MultiTapper(Arduino(), t)

let mrflap = MrFlap(
    imageProvider: WindowInteractor(appName: "AirServer", windowNameHint: "iPhone").imageProvider,
    tapper: tapper,
    debugParameters: DebugParameters(
        location: "/Users/David/Desktop/Debug.noSync",
        occasions: [],
        logEvery: 250,
        content: .all,
        logLast50FramesOnCrash: true
    )
)

Timing.shared.perform(after: 2) {
    mrflap.play()
}

mrflap.crashed += {
    print("CRASHED!")
}

//game.runAsApplication()

RunLoop.main.run()

struct T: SomewhereTapper {
    func tap() {
        print("TAP \(CFAbsoluteTimeGetCurrent())")
    }
}
