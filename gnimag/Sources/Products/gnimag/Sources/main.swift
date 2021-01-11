import Common
import Cocoa
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

// Arduino
let imageProvider = airServer
let tapper = SingleTapArduino(portPath: "/dev/cu.usbmodem14101")

let mrflap = MrFlap(
    imageProvider: imageProvider,
    tapper: tapper,
    debugParameters: DebugParameters(
        location: "/Users/David/Desktop/Debug.noSync",
        occasions: [],
        logEvery: 1000,
        content: .all,
        logLastCoupleFramesOnCrash: true
    )
)

Timing.shared.perform(after: 2) {
    mrflap.play()
}

// Play sound on crash
mrflap.crashed += {
    print("CRASHED!")
    NSSound(named: "Basso")?.play()
    NSSound(named: "Blow")?.play()
    NSSound(named: "Glass")?.play()
}

PowerManager.disableScreenSleep()

RunLoop.main.run()
