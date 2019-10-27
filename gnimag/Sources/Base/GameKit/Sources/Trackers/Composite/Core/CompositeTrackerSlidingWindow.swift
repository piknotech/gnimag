//
//  Created by David Knothe on 08.10.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common

/// CompositeTrackerSlidingWindow plays a role during a decision action of CompositeTracker.
/// Once one data point matches the next segment, following data points are written into the CompositeTrackerSlidingWindow.
/// Once enough data points are in the window, the decision is made (i.e. the segment is either advanced or not) and the appropriate data points are flushed and given to the respective (either old or new) tracker.
internal class CompositeTrackerSlidingWindow<SegmentTrackerType: SimpleTrackerProtocol> {
    private typealias DataPoint = (value: Double, time: Double, matching: Segment)
    
    enum Segment {
        case current
        case next
    }

    /// The characteristics that describe how to make a decision.
    private let characteristics: CompositeTracker<SegmentTrackerType>.NextSegmentDecisionCharacteristics

    /// The stack of data points. The first entry is the oldest one, new entries will be pushed to the back.
    private var dataPoints = [DataPoint]()

    /// The data point that initiated the decision action, i.e. the first data point in the window.
    var decisionInitiator: CompositeTrackerSlidingWindowDelegate.DataPoint? {
        dataPoints.first.map { ($0.value, $0.time) }
    }

    /// The delegate which is informed about decisions and flushed data points.
    unowned var delegate: CompositeTrackerSlidingWindowDelegate!

    /// Default initializer.
    init(characteristics: CompositeTracker<SegmentTrackerType>.NextSegmentDecisionCharacteristics) {
        if characteristics.pointsMatchingNextSegment < 1 || characteristics.maxIntermediatePointsMatchingCurrentSegment < 0 {
            exit(withMessage: "Characteristics invalid!")
        }

        self.characteristics = characteristics
    }

    /// Add a data point to the window.
    /// The incoming data points MUST be sorted monotonically by x value.
    /// If the *first* data point is from the current segment, it is immediately flushed – a decision action will only be initiated when the first data point is from the *next* segment.
    func addDataPoint(value: Double, time: Double, matching segment: Segment) {
        if dataPoints.isEmpty && segment == .current {
            delegate.flushedDataPointsAvailableForCurrentTracker(dataPoints: [(value, time)])
            return
        }

        dataPoints.append(DataPoint(value: value, time: time, matching: segment))
        makeDecisionIfPossible()
    }

    /// Check if a decision can be made and execute it.
    /// This also includes flushing some (or all) of the oldest values if they cannot contribute to a decision anymore.
    private func makeDecisionIfPossible() {
        let matchingCurrent = dataPoints.filter { $0.matching == .current }
        let matchingNext = dataPoints.filter { $0.matching == .next }

        // 1.: Check if there are enough points from next segment
        if matchingNext.count == characteristics.pointsMatchingNextSegment {
            dataPoints.removeAll() // Clear window
            delegate?.madeDecisionToAdvanceToNextTracker(
                withDataPoints: matchingNext.map { ($0.value, $0.time) },
                discardedDataPoints: matchingCurrent.map { ($0.value, $0.time) }
            )
        }

        // 2.: Check if there are too many points from current segment
        if matchingCurrent.count > characteristics.maxIntermediatePointsMatchingCurrentSegment {
            // Remove all up to the first "current" point; then ensure that the window is, again, starting with a "next" point
            dataPoints.dropWhile { $0.matching == .next }
            let flushed = dataPoints.dropWhile { $0.matching == .current }
            delegate?.flushedDataPointsAvailableForCurrentTracker(
                dataPoints: flushed.map { ($0.value, $0.time) }
            )
        }
    }
}

/// The delegate that receives information about decisions and flushed points from CompositeTrackerSlidingWindow.
internal protocol CompositeTrackerSlidingWindowDelegate: class {
    typealias DataPoint = (value: Double, time: Double)

    /// Some (or all) of the oldest values in the window have been flushed because they cannot possibly contribute to the decision (too many data points belonging to the current segment).
    /// These flushed points include both points from the current and the next segment – the parameter `dataPoints` contains only the points from the current segment, as these can now be added to the current tracker.
    func flushedDataPointsAvailableForCurrentTracker(dataPoints: [DataPoint])

    /// Enough values have been collected to advance to the next tracker.
    /// The parameter `dataPoints` contains all points from the window which belong to the next segment – these can be added to the next tracker.
    /// The discarded data points (which matched the current, not the next, tracker) may be of interest to the delegate, so they are also provided.
    func madeDecisionToAdvanceToNextTracker(withDataPoints dataPoints: [DataPoint], discardedDataPoints: [DataPoint])
}
