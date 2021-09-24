//
//  Created by David Knothe on 20.09.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Foundation
import Tapping
import ORSSerial

/// Plotter represents an XY pen plotter which uses an arduino for tapping.
class Plotter {
    private let robot: GRBLDevice
    private let tapper: SingleByteArduino
    let initialized: Event<Void>

    // Sporadic measurements of the iPhone under the plotter, for testing.
    private let deviceWidth: CGFloat = 56
    private let deviceHeight: CGFloat = 103

    // iPad
    //private let deviceWidth: CGFloat = 155
    //private let deviceHeight: CGFloat = 225

    init(penPlotterPath: String, arduinoPath: String) {
        robot = GRBLDevice(path: penPlotterPath)
        tapper = SingleByteArduino(portPath: arduinoPath)
        initialized = robot.initialized

        TerminationHandler.shared.onTerminate += {
            print("move0")
            self.robot.move(to: .zero)
        }
    }
}

extension Plotter: SomewhereTapper {
    func tap() {
        tapper.tap()
    }
}

extension Plotter: AnywhereTapper {
    func tap(at point: CGPoint) {
        move(to: point).onResult(tapper.tap)
    }
}

extension Plotter: Dragger {
    func down() -> Promise<Void> {
        tapper.down()

        let promise = Promise<Void>()
        Timing.shared.perform(after: 0.05, block: promise.fulfill)
        return promise
    }

    func up() {
        tapper.up()
    }

    func move(to point: CGPoint) -> Promise<Void> {
        let promise = Promise<Void>()
        let scaled = CGPoint(x: point.x * deviceWidth, y: (1 - point.y) * deviceHeight)
        robot.move(to: scaled, callback: promise.fulfill)
        return promise
    }
}
