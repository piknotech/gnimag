//
//  Created by David Knothe on 06.11.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Dispatch
import Foundation

open class DebugLogger<Parameters, Frame: DebugFrameProtocol> where Frame.ParameterType == Parameters {
    public let parameters: Parameters

    /// The current debug frame. Enumeration starts at one.
    public private(set) var currentFrame = Frame(index: 1)

    /// The dispatch queue where logging is performed on.
    public let queue: OperationQueue

    private let watchdog = DebugLoggingSpeedWatchdog()

    /// Default initializer.
    /// Calling this initializer creates and empties the logging directory specified in `parameters`.
    public init(parameters: Parameters) {
        self.parameters = parameters

        queue = OperationQueue()
        queue.qualityOfService = .utility

        setup()
    }

    /// Override this method to perform any single-time setup.
    /// This method is automatically called at initialization.
    open func setup() {
    }

    /// Delete, if required, and then recreate the logging directory.
    /// This is not called automatically – call from within "setup" if you want to create a clean logging directory.
    public func createCleanDirectory() {
        try? FileManager.default.removeItem(atPath: parameters.location)
        try! FileManager.default.createDirectory(atPath: parameters.location, withIntermediateDirectories: true)
    }

    /// Log the current frame to disk, if required, and advance to the next frame.
    open func advance() {
        let frame = currentFrame

        // Log frame, asynchronously, if relevant
        if frame.isValidForLogging(with: parameters) {
            frame.prepareSynchronously(with: parameters)

            queue.addOperation {
                self.watchdog.frameWasLogged(frameIndex: frame.index, currentFrameIndex: self.currentFrame.index)
                frame.log(with: self.parameters)
            }
        }

        currentFrame = Frame(index: currentFrame.index + 1)
    }

    /// Log the current frame to disk, if required, synchronously, and advance to the next frame.
    /// Only call when `advance` would be to slow, e.g. if the program will immediately be terminated after this call. Use `force` to force logging, irrespective of the user's logging settings.
    public func logSynchronously(force: Bool = false) {
        // Log frame, synchronously, if relevant
        if force || currentFrame.isValidForLogging(with: parameters) {
            currentFrame.prepareSynchronously(with: parameters)
            currentFrame.log(with: self.parameters)
        }

        currentFrame = Frame(index: currentFrame.index + 1)
    }
}
