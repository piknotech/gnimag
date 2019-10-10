//
//  Created by David Knothe on 08.10.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common

/// CompositeCoreSlidingWindow plays a role during a decision action of CompositeCore.
/// Once one data point matches the next segment, following data points are written into the CompositeCoreSlidingWindow.
/// Once enough data points are in the window, the decision is made (i.e. the segment is either advanced or not) and the appropriate data points are flushed and given to the respective (either old or new) tracker.
internal class CompositeCoreSlidingWindow {
    private typealias DataPoint = (x: Double, y: Double, matching: Segment)
    
    enum Segment {
        case current
        case next
    }

    /// The characteristics that describe how to make a decision.
    private let characteristics: CompositeCore.NextSegmentDecisionCharacteristics

    /// The stack of data points. The first entry is the oldest one, new entries will be pushed to the back.
    private var dataPoints = [DataPoint]()

    /// States whether the window is empty.
    var isEmpty: Bool { dataPoints.isEmpty }

    /// The delegate which is informed about decisions and flushed data points.
    weak var delegate: CompositeCoreSlidingWindowDelegate?

    /// Default initializer.
    init(characteristics: CompositeCore.NextSegmentDecisionCharacteristics) {
        self.characteristics = characteristics
    }

    /// Add a data point to the window.
    /// The incoming data points must be sorted monotonically by x value.
    /// Attention: The first data point must ALWAYS stem from the next segment (as this is the cause of the decision action to be initiiated).
    func addDataPoint(x: Double, y: Double, matching segment: Segment) {
        if dataPoints.isEmpty && segment == .current {
            exit(withMessage: "The first data point must stem from the next segment!")
        }

        dataPoints.append(DataPoint(x: x, y: y, matching: segment))
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
            delegate?.madeDecisionToAdvanceToNextTracker(withDataPoints: matchingNext.map { ($0.x, $0.y) })
        }

        // 2.: Check if there are too many points from current segment
        if matchingCurrent.count > characteristics.maxIntermediatePointsMatchingCurrentSegment {
            // Remove all up to the first "current" point; then ensure that the window is, again, starting with a "next" point
            dataPoints.dropWhile { $0.matching == .next }
            let flushed = dataPoints.dropWhile { $0.matching == .current }
            delegate?.flushedDataPointsAvailableForCurrentTracker(dataPoints: flushed.map { ($0.x, $0.y) })
        }
    }
}

/// The delegate that receives information about decisions and flushed points from CompositeCoreSlidingWindow.
internal protocol CompositeCoreSlidingWindowDelegate: class {
    typealias DataPoint = (x: Double, y: Double)

    /// Some (or all) of the oldest values in the window have been flushed because they cannot possibly contribute to the decision (too many data points belonging to the current segment).
    /// These flushed points include both points from the current and the next segment – the parameter `dataPoints` contains only the points from the current segment, as these can now be added to the current tracker.
    func flushedDataPointsAvailableForCurrentTracker(dataPoints: [DataPoint])

    /// Enough values have been collected to advance to the next tracker.
    /// The parameter `dataPoints` contains all points from the window which belong to the next segment, as these can now be added to the next tracker.
    func madeDecisionToAdvanceToNextTracker(withDataPoints dataPoints: [DataPoint])
}
