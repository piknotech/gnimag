//
//  Created by David Knothe on 27.02.18.
//  Copyright © 2018 Piknotech. All rights reserved.
//

import Foundation

/// Await is a global function that waits until the result of a promise is available.
/// When an error occurs, nil is returned; else, the result is returned.
@discardableResult
public func await<Result>(_ promise: Promise<Result>) -> Result? {
    // Wait in current thread (blocking) until a outcome is available
    while promise.outcome == nil {
        let wakeUpInterval = 0.01
        Thread.sleep(forTimeInterval: wakeUpInterval) // This significantly reduces CPU usage (from 200% to 2%)
    }

    // Return result or nil
    switch promise.outcome! {
    case .result(let result):
        return result

    case .error:
        return nil
    }
}

infix operator &

/// Call `await & task` instead of `await(task)`.
public func &<R>(lhs: (Promise<R>) -> R?, rhs: Promise<R>) -> R? {
    lhs(rhs)
}

/// Block the current thread, waiting until a boolean condition is true.
public func wait(until condition: @autoclosure () -> Bool) {
    while !condition() {
        let wakeUpInterval = 0.01
        Thread.sleep(forTimeInterval: wakeUpInterval) // This significantly reduces CPU usage (from 200% to 2%)
    }
}

/*/// Block the current thread, waiting until a boolean condition is true.
/// The condition evaluation check is synchronized every time.
public func waitSynced(until condition: @autoclosure () -> Bool) {
    while true {
        if synchronized(closure: condition) { break } // Finished once the condition holds
        let wakeUpInterval = 0.01
        Thread.sleep(forTimeInterval: wakeUpInterval) // This significantly reduces CPU usage (from 200% to 2%)
    }
}*/

/// Wait until a boolean condition is true; then perform a block.
/// Both the condition evaluation and the closure performance are locked, so these are an ATOMIC operation.
/// Returns the result that the closure returns.
public func waitAtomic<T>(until condition: @autoclosure () -> Bool, synced object: AnyObject, block: @escaping () -> T) -> T {
    while true {
        // Do condition and block evaluation in a single synchronized block
        let ret = synchronized(object) { () -> T? in
            if condition() {
                return block()
            } else {
                return nil
            }
        }

        // Stop waiting after successful condition
        if let ret = ret {
            return ret
        }

        // Sleep for 0.01 seconds
        let wakeUpInterval = 0.01
        Thread.sleep(forTimeInterval: wakeUpInterval)
    }
}

/// Use async to create a promise that simply consists of executing a function.
/// The function is executed on a background thread. Its result will then be the result of the promise.
public func async<Result>(_ function: @escaping () -> Result?) -> Promise<Result> {
    let promise = Promise<Result>()

    // Execute function in background
    Thread.detachNewThread {
        if let result = function() {
            promise.finished(with: .result(result))
        } else {
            promise.finished(with: .error)
        }
    }

    return promise
}
