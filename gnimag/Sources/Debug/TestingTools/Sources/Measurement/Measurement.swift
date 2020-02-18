//
//  Created by David Knothe on 06.08.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import QuartzCore

public enum Measurement {
    private static var runningMeasurements = [String: TimeInterval]()

    /// Begin or restart a measurement with the given identifier.
    public static func begin(id: String) {
        runningMeasurements[id] = CACurrentMediaTime()
    }

    /// End the measurement with the given identifier and print the result in milliseconds.
    public static func end(id: String) {
        let time = CACurrentMediaTime()

        if let index = runningMeasurements.index(forKey: id) {
            let (_, startTime) = runningMeasurements.remove(at: index)
            Terminal.log(.nice, "Task \"\(id)\" took \(1000 * (time - startTime)) ms!")
        } else {
            Terminal.log(.warning, "There is no task named \"\(id)\"!")
        }
    }

    /// End all running measurements.
    public static func endAll() {
        let time = CACurrentMediaTime()

        for (id, startTime) in runningMeasurements {
            Terminal.log(.nice, "Task \"\(id)\" took \(1000 * (time - startTime)) ms!")
        }

        runningMeasurements.removeAll()
    }

    /// End all running measurements and begin a new onea with the given identifier.
    public static func next(id: String) {
        endAll()
        runningMeasurements[id] = CACurrentMediaTime()
    }
}
