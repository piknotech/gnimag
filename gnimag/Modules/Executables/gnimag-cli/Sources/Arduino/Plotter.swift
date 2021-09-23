//
//  Created by David Knothe on 20.09.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Foundation
import Tapping
import ORSSerial

/// Plotter represents an XY pen plotter which uses an arduino for tapping.
class Plotter: AnywhereTapper {
    private let robot: GRBLDevice
    private let tapper: SingleByteArduino
    let initialized: Event<Void>

    // Sporadic measurements of the iPhone under the plotter, for testing.
    private let deviceWidth: CGFloat = 50
    private let deviceHeight: CGFloat = 95

    init(penPlotterPath: String, arduinoPath: String) {
        robot = GRBLDevice(path: penPlotterPath)
        tapper = SingleByteArduino(portPath: arduinoPath)
        initialized = robot.initialized

        TerminationHandler.shared.onTerminate += {
            print("move")
            self.robot.move(to: .zero)
        }
    }

    func tap(at point: CGPoint) {
        print("tap at \(point)")
        let scaled = CGPoint(x: point.x * deviceWidth, y: (1 - point.y) * deviceHeight)
        robot.move(to: scaled) {
            self.tapper.tap()
        }
    }
}
