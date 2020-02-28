//
//  Created by David Knothe on 14.11.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
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
        case onErrorsTextOnly

        /// Log text and images, but only for integrity errors.
        case onIntegrityErrors

        /// Always log text. Log text and images on errors.
        case alwaysText

        /// Always log text and images.
        case always

        /// Log every x frames with text and images; do not log errors explicitly.
        case every(Int)

        /// True if logging of images is disabled.
        var noImages: Bool {
            switch self {
            case .none, .onErrorsTextOnly: return true
            default: return false
            }
        }

        /// True if images are logged always, independent of whether an error has occurred or not.
        var alwaysImages: Bool {
            switch self {
            case .always, .every: return true
            default: return false
            }
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
