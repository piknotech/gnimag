//
//  Created by David Knothe on 17.04.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

extension JumpTracker {
    /// Debug information about the gravity and jump velocity trackers.
    /// Only use this information read-only!
    public var debug: Debug { Debug(gravityTracker: gravityTracker, jumpVelocityTracker: jumpVelocityTracker) }

    public struct Debug {
        public let gravityTracker: ConstantTracker
        public let jumpVelocityTracker: ConstantTracker
    }
}
