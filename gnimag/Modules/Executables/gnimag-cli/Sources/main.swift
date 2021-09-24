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

Permissions.checkOnStartup()
PowerManager.disableScreenSleep()

let plotter = Plotter(penPlotterPath: "/dev/cu.usbserial-14240", arduinoPath: "/dev/cu.usbmodem142201")

if CommandLine.arguments.contains("tap") {
    Timing.shared.perform(after: 2) {
        plotter.tap(); plotter.tap(); plotter.tap()
    }
}
else if CommandLine.arguments.contains("identiti") {
    let game = identiti(imageProvider: airServer, tapper: plotter, os: .iOS)
    Timing.shared.perform(after: 2, block: game.play)
}
else if CommandLine.arguments.contains("mrflap") {
    let game = MrFlap(imageProvider: airServer, tapper: plotter)
    Timing.shared.perform(after: 2, block: game.play)
}
else if CommandLine.arguments.contains("tp") {
    let game = ThreePoints(imageProvider: airServer, tapper: plotter)
    Timing.shared.perform(after: 2, block: game.play)
}
else if CommandLine.arguments.contains("fm") {
    let game = FreakingMath(imageProvider: airServer, tapper: plotter, game: .normal)
    Timing.shared.perform(after: 2, block: game.play)
}
else if CommandLine.arguments.contains("fm+") {
    let game = FreakingMath(imageProvider: airServer, tapper: plotter, game: .plus)
    Timing.shared.perform(after: 2, block: game.play)
}
else if CommandLine.arguments.contains("flowfree") {
    let game = FlowFreeSingleLevel(imageProvider: airServer, dragger: plotter)
    Timing.shared.perform(after: 2, block: game.play)
}

TerminationHandler.shared.onTerminate += {
    Timing.shared.perform(after: 0.5) {
        exit(0)
    }
}

RunLoop.main.run()
