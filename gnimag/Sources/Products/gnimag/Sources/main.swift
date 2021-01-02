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

/*
// Simulation
let game = MrFlapGameSimulation(fps: 50)
let imageProvider = game
let tapper = game
*/

// Arduino
let imageProvider = WindowInteractor(appName: "AirServer", windowNameHint: "iPhone").imageProvider
//let imageProvider = WindowInteractor(appName: "QuickTime Player").imageProvider
let tapper = MultiTapper(Arduino(), T())
struct T: SomewhereTapper {
     func tap() {
        print("TAP \(imageProvider.timeProvider.currentTime)")
     }
}

/* TestRun Hard
let imageProvider = ImageListProvider(directoryPath: "/Users/David/Desktop/ /gnimag-test/TestRun Hard", framerate: 60)
let tapper = NoopTapper()
*/

let mrflap = MrFlap(
    imageProvider: imageProvider,
    tapper: tapper,
    debugParameters: DebugParameters(
        location: "/Users/David/Desktop/Debug.noSync",
        occasions: [],
        logEvery: 250,
        content: .all,
        logLastCoupleFramesOnCrash: true
    )
)

Timing.shared.perform(after: 2) {
    mrflap.play()
}

mrflap.crashed += {
    print("CRASHED!")
    NSSound(named: "Basso")?.play()
    NSSound(named: "Blow")?.play()
    NSSound(named: "Glass")?.play()
}

// game.runAsApplication()


PowerManager.disableScreenSleep()

RunLoop.main.run()
