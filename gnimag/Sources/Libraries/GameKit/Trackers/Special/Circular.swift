//
//  Created by David Knothe on 22.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

/// Circular provides a wrapper around trackers whose value range is in [0, 2*pi). It converts angular values back into linear values.

public class Circular<Tracker: PolyTracker> {
    
    /// The internal tracker tracking the "linearified" values.
    /// Do not add values to it directly.
    private let tracker: Tracker
    
    /// The lastly added value.
    private var lastValue: Tracker.Value!
    
    /// Default initializer.
    public init(_ tracker: Tracker) {
        self.tracker = tracker
    }
    
    /// "Linearify" the value and add it to the tracker.
    public func add(value: Tracker.Value, at time: Tracker.Time) {
        // Use the tracker regression or the last added value as an approximation
        if let guess = tracker.regression?.f(time) ?? lastValue {
            // Get best matching rotation value
            let distance = guess - value
            let rotations = floor((distance + .pi) / (2 * .pi))
            let value = value + rotations * 2 * .pi
            
            // Add the "linearified" value
            tracker.add(value: value, at: time)
            lastValue = value
        }
        
        else {
            // Simply add value on first call
            tracker.add(value: value, at: time)
            lastValue = value
        }
    }
    
    /// Convert a given angular value in [0, 2*pi) to a linear value that is directly near the current tracker value.
    /// Assumes that a regression function is available.
    public func linearifyToNextMatch(_ angle: Double, at time: Double) -> Double {
        let value = tracker.regression!.f(time)
        
        // Add number of rotations until the angle is near the current tracker value
        let rotations = round((value - angle) / (2 * .pi))
        let angle = angle + rotations * 2 * .pi
        return angle
    }
}
