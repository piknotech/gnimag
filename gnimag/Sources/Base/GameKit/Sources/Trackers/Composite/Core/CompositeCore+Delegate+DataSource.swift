//
//  Created by David Knothe on 08.10.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

public protocol CompositeCoreDelegate: class {
    /// Called each time the regression function or the guesses of the current segment are updated, i.e. each time a new point is added to the current segment.
    /// This is called at least once per segment.
    func currentSegmentWasUpdated(segment: CompositeCore.SegmentInfo)

    /// Called when the current segment is being finalized and focus moves to the next segment.
    /// The segment does not necessarily have a regression function, but it has at least a regression function or guesses.
    /// Called exactly once per segment.
    func advancedToNextSegmentAndFinalizedLastSegment(lastSegment: CompositeCore.SegmentInfo)
}

public protocol CompositeCoreDataSource: class {
    /// Make a guess for the next partial function which begins at the given split position.
    /// If you don't have enough information for making the guess, return nil.
    func guessForNextPartialFunction(whenSplittingSegmentsAtX x: Double, y: Double) -> SmoothFunction?

    /// Called exactly once per segment to create an appropriate empty tracker for the next partial function.
    /// This will be called **after** `advancedToNextSegmentAndFinalizedLastSegment` is called on the delegate.
    func trackerForNextSegment() -> SimpleTrackerProtocol
}
