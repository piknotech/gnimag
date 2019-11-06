//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import MacTestingTools

/// MedianTracker continuously calculates the median value of the given stream of data points.
public final class MedianTracker {
    public typealias Value = Double

    /// The sorted array of values.
    fileprivate var values = [Value]()
    
    /// The maximum number of data points.
    /// When reaching this limit, half of the elements will be removed.
    private let maxDataPoints: Int
    
    /// Default initializer.
    public init(maxDataPoints: Int = 100) {
        self.maxDataPoints = maxDataPoints
    }
    
    /// Add a value to the tracker and update the median.
    public func add(value: Value) {
        // Check number of data points
        if values.count == maxDataPoints {
            values.removeFirst(maxDataPoints / 4)
            values.removeLast(maxDataPoints / 4)
        }
        
        // Insert value
        let index = values.binarySearch(for: value)
        values.insert(value, at: index)
        
        // Get median
        if values.count % 2 == 0 {
            median = (values[values.count / 2] + values[values.count / 2 - 1]) / 2
        } else {
            median = values[values.count / 2]
        }
    }
    
    /// The median value.
    /// Nil when no value has been added yet.
    public private(set) var median: Value?
}


// MARK: HasScatterDataSet
extension MedianTracker: HasScatterDataSet {
    /// Return the raw data from the tracker.
    public var dataSet: [ScatterDataPoint] {
        let x = (0 ..< values.count).map(Double.init)
        return zip(x, values).map(ScatterDataPoint.init(x:y:))
    }
}

// MARK: Array+BinarySearch
fileprivate extension Array where Element: Comparable {
    /// Find the index i so that self[0...i] is <= value, and that self[(i+1)...] is > value.
    /// Precondition: self is sorted ascending.
    func binarySearch(for value: Element) -> Index {
        var low = startIndex
        var high = endIndex
        
        // Search loop
        while low != high {
            let mid = low + (high - low) / 2
            if value > self[mid] {
                low = mid + 1
            } else {
                high = mid
            }
        }
        
        return low
    }
}
