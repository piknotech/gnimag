//
//  Created by David Knothe on 25.01.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation

/// Timing provides the possibility to perform a task after a certain amount of time.
/// Tasks can be tagged with an identification to be cancelled at a later point.
public class Timing {
    /// Create a new private instance of Timing.
    public init() {
    }

    /// The shared Timing instance. You can use it as a shortcut if you don't need a custom Timing instance.
    public static let shared = Timing()

    /// All running timers.
    private var timers = [Timer]()

    /// Schedule the timer with the given callback.
    /// You can provide an identification for later cancellation.
    /// If `delay <= 0`, the block is executed (quasi) immediately (not necessarily in the same thread).
    public func perform(after delay: TimeInterval, identification: Identification = .empty, block: @escaping () -> Void) {
        synchronized(self) {
            let userInfo = UserInfo(block: block, identification: identification)
            let timer = Timer(timeInterval: delay, target: self, selector: #selector(fire(timer:)), userInfo: userInfo, repeats: false)
            timers.append(timer)
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    /// Cancel all scheduled tasks.
    public func cancelAllTasks() {
        _ = cancelTasks { _ in true }
    }

    /// Cancel all scheduled tasks exactly matching the given identification.
    /// Returns `true` if at least one timer has been cancelled.
    @discardableResult
    public func cancelTasks(matching identification: Identification) -> Bool {
        cancelTasks {
            let userInfo = $0.userInfo as! UserInfo
            return userInfo.identification.exactlyMatches(other: identification)
        }
    }

    /// Cancel all scheduled tasks matching the given object, regardless of their ID or string.
    /// Returns `true` if at least one timer has been cancelled.
    @discardableResult
    public func cancelTasks(withObject object: AnyObject) -> Bool {
        cancelTasks {
            let userInfo = $0.userInfo as! UserInfo
            return Identification.object(object).contains(other: userInfo.identification)
        }
    }

    /// Common method for cancelling timers based on a decision handler.
    private func cancelTasks(decisionHandler shouldCancelTimer: (Timer) -> Bool) -> Bool {
        synchronized(self) {
            var cancelled = false

            timers.removeAll {
                let matches = shouldCancelTimer($0)
                if matches { $0.invalidate() }
                cancelled = cancelled || matches
                return matches
            }

            return cancelled
        }
    }

    /// Perform the callback and remove the timer.
    @objc
    private func fire(timer: Timer) {
        synchronized(self) {
            if !timer.isValid { return } // Timer may just have been cancelled from another thread

            // Remove timer from dictionary
            guard let index = (timers.firstIndex { $0 === timer }) else { return }
            timers.remove(at: index)

            let userInfo = (timer.userInfo as! UserInfo)
            userInfo.block()
        }
    }

    /// A simple class providing user info that is used in conjunction with a timer.
    private class UserInfo {
        let block: () -> Void
        let identification: Identification

        init(block: @escaping () -> Void, identification: Identification) {
            self.block = block
            self.identification = identification
        }
    }

    /// A struct bundling a variety of ways to uniquely identify tasks.
    /// An identification can consist of zero to all of the provided possibilities.
    public struct Identification {
        public let object: AnyObject?
        public let id: UUID?
        public let string: String?

        /// Default initializer.
        public init(object: AnyObject? = nil, id: UUID? = nil, string: String? = nil) {
            self.object = object
            self.id = id
            self.string = string
        }

        /// The empty identification, only containing nil values.
        public static let empty = Identification()

        /// Shortcut to create an Identification consisting of an object.
        public static func object(_ object: AnyObject, id: UUID? = nil, string: String? = nil) -> Identification {
            Identification(object: object, id: id, string: string)
        }

        /// Shortcut to create an Identification consisting of an id.
        public static func id(_ id: UUID, string: String? = nil) -> Identification {
            Identification(id: id, string: string)
        }

        /// Shortcut to create an Identification consisting just of a string.
        public static func string(_ string: String) -> Identification {
            Identification(string: string)
        }

        /// Check whether this Identification exactly matches the other one. This means, all non-nil properties must match, and all nil properties must be nil on both objects.
        public func exactlyMatches(other: Identification) -> Bool {
            object === other.object && id == other.id && string == other.string
        }

        /// Check whether this Identification is a (non-strict) superset of the other one. This means, all non-nil properties must match.
        /// All nil properties of `self` are wildcards matching any value of the other Identfication.
        /// For example, the empty Identification contains any Identification.
        public func contains(other: Identification) -> Bool {
            if let object = object, object !== other.object { return false }
            if let id = id, id != other.id { return false }
            if let string = string, string != other.string { return false }
            return true
        }
    }
}
