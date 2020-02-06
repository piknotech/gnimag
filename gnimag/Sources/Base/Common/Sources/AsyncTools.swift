//
//  Created by David Knothe on 09.04.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

/// Synchronize a code of block, so only one thread can enter it at any given time.
public func synchronized<T>(_ object: AnyObject, _ closure: () -> T) -> T {
    objc_sync_enter(object)
    defer { objc_sync_exit(object) }
    return closure()
}

/// Run a piece of code on a, newly created, background thread.
/// The thread has a high priority and a high QoS (good for calculations etc. Not good for waiting).
/// This is NOT done via a dispatch queue because we found that creating a thread manually performs faster calculations than a dispatch queue most of the time.
public func inBackgroundThread(code: @escaping () -> Void) {
    let t = Thread(block: code)
    t.qualityOfService = .userInitiated
    t.threadPriority = 1
    t.start()
}
