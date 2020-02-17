//
//  Created by David Knothe on 06.11.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Dispatch

open class DebugLogger<Parameters, Frame: DebugFrameProtocol> where Frame.ParameterType == Parameters {
    public let parameters: Parameters

    /// The current debug frame. Enumeration starts at one.
    public private(set) var currentFrame = Frame(index: 1)

    /// Default initializer.
    /// Calling this initializer creates and empties the logging directory specified in `parameters`.
    public init(parameters: Parameters) {
        self.parameters = parameters
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
    public func advance() {
        let frame = currentFrame

        // Log frame, asynchronously, if relevant
        if frame.isValidForLogging(with: parameters) {
            frame.prepareSynchronously(with: parameters)
            DispatchQueue.global(qos: .utility).async {
                frame.log(with: self.parameters)
            }
        }

        currentFrame = Frame(index: currentFrame.index + 1)
    }
}
