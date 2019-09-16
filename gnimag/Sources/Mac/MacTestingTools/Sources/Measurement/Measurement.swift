//
//  Created by David Knothe on 06.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import Foundation

public enum Measurement {
    private static var runningMeasurements = [String: TimeInterval]()

    /// Begin or restart a measurement with the given identifier.
    public static func begin(id: String) {
        runningMeasurements[id] = CFAbsoluteTimeGetCurrent()
    }

    /// End the measurement with the given identifier and print the result in milliseconds.
    public static func end(id: String) {
        let time = CFAbsoluteTimeGetCurrent()

        if let index = runningMeasurements.index(forKey: id) {
            let (_, startTime) = runningMeasurements.remove(at: index)
            log(.nice, "Task \"\(id)\" took \(1000 * (time - startTime)) ms!")
        } else {
            log(.warning, "There is no task named \"\(id)\"!")
        }
    }
}
