//
//  Created by David Knothe on 09.09.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

/// Use Terminal.log to log messages along with severities to the terminal.
public enum Terminal {
    private static let lock = NSObject()

    public enum LoggingSeverity: CustomStringConvertible {
        case party
        case nice
        case info
        case warning
        case error
        case fatal // Only use "fatal" when the program cannot be executed further from hereon. You can use "exit(withMessage:)" for this purpose.

        public var description: String {
            switch self {
            case .party: return "🎉"
            case .nice: return "✅"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .fatal: return "⛔️⛔️⛔️⛔️⛔️"
            }
        }
    }

    /// Log a message with a given severity.
    public static func log(_ severity: LoggingSeverity = .info, _ message: Any) {
        synchronized(lock) {
            print(severity, terminator: "  ")
            print(message)
        }
    }

    /// Write a newline to the log.
    public static func logNewline() {
        synchronized(lock) {
            print()
        }
    }
}

/// Write a fatal log using Terminal and stop the program execution.
public func exit(withMessage message: String) -> Never {
    Terminal.log(.fatal, message)
    raise(SIGINT) // Enable debugging
    exit(1)
}
