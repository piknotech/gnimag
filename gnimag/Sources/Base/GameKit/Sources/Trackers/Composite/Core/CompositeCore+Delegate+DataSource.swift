//
//  Created by David Knothe on 08.10.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

public protocol CompositeCoreDelegate {
    /// Called each time the regression function of the current segment is updated.
    func currentSegmentRegressionFunctionUpdated(function: SmoothFunction)

    /// Called exactly once per segment, namely when the segment is being finalized and focus moves to the next segment.
    /// When the current segment is finalized, its regression function is set finally.
    func advancedToNextSegmentAndFinalizedRegressionFunctionOfLastSegment(function: SmoothFunction)
}

public protocol CompositeCoreDataSource {
    /// Make a guess for the next partial function which begins at the given split position.
    /// If you don't have enough information for making the guess, return nil.
    func guessForNextPartialFunction(whenSplittingSegmentsAt splitXPos: Double) -> SmoothFunction?

    /// Called once per segment to create an appropriate empty tracker for the next partial function.
    /// This is called before `advancedToNextSegmentAndFinalizedRegressionFunctionOfLastSegment` is called on the delegate.
    func trackerForNextSegment() -> SimpleTrackerProtocol
}

// TODO: what about segments with too little data points?! Is `advancedToNextSegmentAndFinalizedRegressionFunctionOfLastSegment` called?

// TODO: 2 verschiedene PingPongTracker!
