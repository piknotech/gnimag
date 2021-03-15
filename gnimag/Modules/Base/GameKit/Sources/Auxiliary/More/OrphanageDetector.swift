//
//  Created by David Knothe on 13.02.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

/// Use OrphanageDetector to detect whether an object is orphaned, i.e. has not been updated recently.
/// This could happen either when such an object leaves the screen or when it was created erroneously.
public class OrphanageDetector {
    /// The number of consecutive frames that have not been marked valid via `markAsValid`.
    private var consecutiveNumberOfFramesWithoutUpdate = 0

    /// When `newFrame` is called more than `maxFramesWithoutUpdate` times without a `markAsValid` in the meantime, this object gets marked as orphaned.
    private let maxFramesWithoutUpdate: Int

    public var isOrphaned: Bool {
        consecutiveNumberOfFramesWithoutUpdate > maxFramesWithoutUpdate
    }

    /// Default initializer.
    public init(maxFramesWithoutUpdate: Int) {
        self.maxFramesWithoutUpdate = maxFramesWithoutUpdate
    }

    /// Call at the beginning of each frame. This increases the `consecutiveNumberOfFramesWithoutUpdate` counter.
    public func newFrame() {
        consecutiveNumberOfFramesWithoutUpdate += 1
    }

    /// Call when the object has been updated and is valid. This resets the `consecutiveNumberOfFramesWithoutUpdate` counter.
    public func markAsValid() {
        consecutiveNumberOfFramesWithoutUpdate = 0
    }
}
