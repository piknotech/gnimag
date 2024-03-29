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
import ThreePoints

let arduino = SingleByteArduino(portPath: "/dev/cu.usbmodem14101")
let arguments = CommandLine.arguments
// let arguments = ["tp"]

if arguments.contains("tap") {
    Timing.shared.perform(after: 2) {
        arduino.tap()
        arduino.tap()
        arduino.tap()
        exit(0)
    }
}

else if arguments.contains("tp") {
    Permissions.checkOnStartup()

    let imageProvider = quickTime
    let tapper = arduino
    let threePoints = ThreePoints(imageProvider: imageProvider, tapper: tapper)

    Timing.shared.perform(after: 2) {
        threePoints.play()
    }
}

else if arguments.contains("mrflap") {
    Permissions.checkOnStartup()

    let imageProvider = airServer // scrcpy.imageProvider.resizingImages(factor: 0.5)
    let tapper = arduino

    let mrflap = MrFlap(
        imageProvider: imageProvider,
        tapper: tapper,
        debugParameters: DebugParameters(
            location: NSHomeDirectory() +/ "Desktop/Debug.noSync",
            occasions: [],
            logEvery: 1000,
            content: .all,
            logLastCoupleFramesOnCrash: true
        )
    )

    Timing.shared.perform(after: 2) {
        mrflap.play()
    }
}

PowerManager.disableScreenSleep()
RunLoop.main.run()
