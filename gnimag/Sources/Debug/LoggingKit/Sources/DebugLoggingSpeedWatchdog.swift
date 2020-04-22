//
//  Created by David Knothe on 22.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Darwin
import Foundation
import GameKit

import TestingTools

/// When debug logging is happening too often, it might not be fast enough to keep up in real time.
/// This means that, over time, more and more debug frames (which are from old frames but have not yet been processed) get piled up and fill up the memory.
/// When this happens, DebugLoggingSpeedWatchdog writes warnings to the terminal.
internal class DebugLoggingSpeedWatchdog {
    private let tracker = LinearTracker(maxDataPoints: .max, tolerance: .absolute(0))

    /// The damper enforcing a minimum delay between warning messages.
    private var loggingDamper = ActionStreamDamper(delay: 10, performFirstActionImmediately: false)

    /// Call when a new frame was logged.
    /// If required, this will write a warning to the terminal.
    func frameWasLogged(frameIndex: Int, currentFrameIndex: Int) {
        tracker.add(value: Double(frameIndex), at: Double(currentFrameIndex))

        if let slope = tracker.slope, slope < 0.95, currentFrameIndex - frameIndex > 50 {
            loggingDamper.perform {
                ScatterPlot(from: tracker).writeToDesktop(name: "\(slope).png")
                Terminal.log(.error, "DebugLogger cant't keep up with the logging workload in real-time! (logging frame \(frameIndex) while current frame is \(currentFrameIndex)). Over time, memory will get filled up more and more with DebugFrames. Current memory load: \(getMemoryUsage() ??? "nil") MB.")
            }
        }
    }
}

/// Get the current memory usage of the application in MB.
private func getMemoryUsage() -> Double? {
    var info = mach_task_basic_info()
    let MACH_TASK_BASIC_INFO_COUNT = MemoryLayout<mach_task_basic_info>.stride / MemoryLayout<natural_t>.stride
    var count = mach_msg_type_number_t(MACH_TASK_BASIC_INFO_COUNT)

    let result: kern_return_t = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: MACH_TASK_BASIC_INFO_COUNT) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
        }
    }

    if result == KERN_SUCCESS {
        return Double(info.resident_size) / 1e6
    } else {
        return nil
    }
}
