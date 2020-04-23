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

let mrflap = MrFlap(
    imageProvider: scrcpy.imageProvider,
    tapper: scrcpy.tapper,
    debugParameters: DebugParameters(
        location: "/Users/David/Desktop/Debug.noSync",
        occasions: [.errors, .interestingTapPrediction],
        logEvery: 20,
        content: .all
    )
)

mrflap.play()

mrflap.crashed += {
    print("CRASHED!")
}

RunLoop.main.run()
