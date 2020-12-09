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

// let a = ScreenInteractor(frame: CGRect(x: 332, y: 68, width: 778, height: 767))
// let a = ImageListProvider(directoryPath: "/Users/David/Desktop/I", framerate: 50)
// let game = MrFlapGameSimulation(fps: 50)

let mrflap = MrFlap(
    imageProvider: vysor.imageProvider,
    tapper: vysor.tapper,
    debugParameters: DebugParameters(
        location: "/Users/David/Desktop/Debug.noSync",
        occasions: [],
        logEvery: nil,
        content: .all,
        logLast50FramesOnCrash: true
    )
)

mrflap.play()

mrflap.crashed += {
    print("CRASHED!")
}

RunLoop.main.run()
