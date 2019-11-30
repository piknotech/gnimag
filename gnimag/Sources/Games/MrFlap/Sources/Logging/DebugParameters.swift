//
//  Created by David Knothe on 14.11.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import LoggingKit

/// DebugParameters allow the user of MrFlap to configure the location and the severity of the debug logging.
public struct DebugParameters: DebugParameterType {
    /// The path to the directory in which the logging is performed.
    public let location: String

    /// The logging severity.
    public let severity: Severity

    public enum Severity {
        case none

        /// Log text and images on errors.
        /// Error means either an image analysis error or a data integrity error.
        case onErrors

        /// Log text on errors.
        /// Error means either an image analysis error or a data integrity error.
        case textOnly

        /// Always log text. Log text and images on errors.
        case alwaysText

        /// True if logging of images is disabled.
        var noImages: Bool {
            return [.none, .textOnly].contains(self)
        }
    }

    /// Default initializer.
    public init(location: String, severity: Severity) {
        self.location = location
        self.severity = severity
    }

    /// Shorthand for no logging.
    public static let none = DebugParameters(location: "", severity: .none)
}
