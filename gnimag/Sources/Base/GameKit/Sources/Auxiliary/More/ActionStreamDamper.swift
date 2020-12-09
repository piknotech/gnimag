//
//  Created by David Knothe on 22.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import QuartzCore

/// ActionStreamDamper can receive a (continuous or not) stream of actions. Its job is to make sure that actions are only performed with a certain delay in between them. This means, when an action was performed, new incoming will not be performed until the delay has been overcome. Then, the next incoming action will be performed.
/// Actions are not retained, i.e. an action coming in during the waiting time will be discarded.
public struct ActionStreamDamper {
    private let delay: Double

    /// When `true`, the first incoming action (also after a `reset`) will be performed immediately. Else, a delay is applied after the first incoming action **without** performing it.
    private let shouldPerformFirstActionImmediately: Bool

    /// The time the last action was executed at.
    private var lastActionExecutionTime: Double?

    /// Default initializer.
    public init(delay: Double, performFirstActionImmediately: Bool) {
        self.delay = delay
        self.shouldPerformFirstActionImmediately = performFirstActionImmediately
    }

    /// Try performing an action.
    public mutating func perform(action: () -> Void) {
        let currentTime = CACurrentMediaTime()

        if let time = lastActionExecutionTime {
            if currentTime - time >= delay {
                lastActionExecutionTime = currentTime
                action()
            }
        }

        else { // First action after `reset` call
            lastActionExecutionTime = currentTime
            if shouldPerformFirstActionImmediately {
                action()
            }
        }
    }

    /// Reset the running delay.
    /// This means the next incoming action will be performed (if `shouldPerformFirstActionImmediately`) and a new delay will be set.
    public mutating func reset() {
        lastActionExecutionTime = nil
    }
}
