//
//  Created by David Knothe on 25.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

/// Timing provides the possibility to perform a task after a certain amount of time.
/// Tasks can be cancelled if they have been tagged with an identifier or an object.
public class Timing {
    private init() { }

    /// All running timers.
    private static var timers = [Timer]()

    /// Cancel all timer with the given identifier and object, if existing.
    public static func cancelPerform(identifier: String? = nil, object: AnyObject? = nil) {
        timers.removeAll {
            let userInfo = $0.userInfo as! UserInfo
            let matches = userInfo.identifier == identifier && userInfo.object === object
            if matches { $0.invalidate() }
            return matches
        }
    }

    /// Schedule the timer with the given callback.
    /// You can provide a string and an object for later cancellation.
    public static func perform(after delay: TimeInterval, identifier: String? = nil, object: AnyObject? = nil, block: @escaping () -> Void) {
        let userInfo = UserInfo(block: block, identifier: identifier, object: object)
        let timer = Timer(timeInterval: delay, target: self, selector: #selector(fire(timer:)), userInfo: userInfo, repeats: false)
        timers.append(timer)
        RunLoop.main.add(timer, forMode: .common)
    }

    /// Perform the callback and remove the timer.
    @objc
    public static func fire(timer: Timer) {
        let userInfo = (timer.userInfo as! UserInfo)
        userInfo.block()

        // Remove timer from dictionary
        let index = timers.firstIndex { $0.userInfo as! UserInfo === userInfo }!
        timers.remove(at: index)
    }

    /// A simple class providing user info that is used in conjunction with a timer.
    private class UserInfo {
        let block: () -> Void
        let identifier: String?
        let object: AnyObject?

        init(block: @escaping () -> Void, identifier: String?, object: AnyObject?) {
            self.block = block
            self.identifier = identifier
            self.object = object
        }
    }
}
