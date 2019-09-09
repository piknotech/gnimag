//
//  Created by David Knothe on 09.09.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

public enum Logger {
    /// The logger that is used when calling the global "log" function.
    /// By default, this is a PrintLogger instace. You can change this from your client application.
    /// Set it to `nil` to disable logging.
    static var shared: LoggerProtocol? = PrintLogger()
}

public enum LoggingSeverity {
    case party
    case nice
    case info
    case warning
    case error
    case fatal // Only use "fatal" when the program cannot be executed further from hereon. You can use "exit(withMessage:) for this purpose".
}

/// Beautiful descriptions for logging severities.
extension LoggingSeverity: CustomStringConvertible {
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

/// Protocol defining requirements for a Logger.
/// When implementing the logging methods, synchronize any write accesses to files/stdout etc. as the logger can be called from multiple threads simultaneously.
public protocol LoggerProtocol {
    /// Log a message with a given severity.
    func log(_ severity: LoggingSeverity, _ message: Any)

    /// Write a newline to the log.
    func logNewline()
}

/// PrintLogger is a logger that logs its output to the console.
/// By default, the shared logger is the PrintLogger.
public final class PrintLogger: LoggerProtocol {
    /// Log a message with a given severity.
    public func log(_ severity: LoggingSeverity = .info, _ message: Any) {
        synchronized(self) {
            print(severity, terminator: "  ")
            print(message)
        }
    }

    /// Write a newline to the log.
    public func logNewline() {
        synchronized(self) {
            print()
        }
    }
}

// MARK: Global Log Methods

/// Use Logger.shared to log the given message.
/// If Logger.shared is nil, do nothing.
public func log(_ severity: LoggingSeverity, _ message: Any) {
    Logger.shared?.log(severity, message)
}

/// Use Logger.shared to log the newline.
/// If Logger.shared is nil, do nothing.
public func logNewline() {
    Logger.shared?.logNewline()
}

/// Write a fatal log using Logger.shared and stop the program execution.
public func exit(withMessage message: String) -> Never {
    log(.fatal, message)
    exit(1)
}
