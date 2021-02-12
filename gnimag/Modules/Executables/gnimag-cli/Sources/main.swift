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
let imageProvider = scrcpy.imageProvider // airServer
let tapper = scrcpy.tapper // SingleByteArduino(portPath: "/dev/cu.usbmodem14101")

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

mrflap.crashed += {
    print("CRASHED!")
}

PowerManager.disableScreenSleep()

RunLoop.main.run()
