//
//  Created by David Knothe on 06.11.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Dispatch

final class DebugLogger {
    private let parameters: DebugParameters

    /// The current debug frame. Enumeration starts at one.
    private(set) var currentFrame = DebugLoggerFrame(index: 1)

    /// Default initializer.
    init(parameters: DebugParameters) {
        self.parameters = parameters

        createDirectory()
    }

    // Delete, if required, and then create the logging directory.
    private func createDirectory() {
        switch parameters.severity {
        case .alwaysText, .onErrors:
            try? FileManager.default.removeItem(atPath: parameters.location)
            try! FileManager.default.createDirectory(atPath: parameters.location, withIntermediateDirectories: true)
        case .none:
            break
        }
    }

    /// Log the current frame to disk, if required, and advance to the next frame.
    func advance() {
        if currentFrame.isValidForLogging(forSeverity: parameters.severity) {
            let frame = currentFrame
            DispatchQueue.global(qos: .utility).async {
                frame.log(to: self.parameters.location, severity: self.parameters.severity)
            }
        }

        currentFrame = DebugLoggerFrame(index: currentFrame.index + 1)
    }
}
