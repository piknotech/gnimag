//
//  Created by David Knothe on 25.12.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation

/// A PreliminaryTracker is a ConstantTracker calculating the average of a value stream.
/// Additionally, a value can be added as being "preliminary", meaning it will be updated and replaced from now on until being finalized.
/// There can only be one preliminary value, which is the latest one.
public final class PreliminaryTracker: ConstantTracker {
    private var lastValueIsPreliminary = false

    /// Add a value non-preliminarily – mark it as final.
    /// If there currently is a preliminary value, it will be finalized (instead of being removed).
    public func addFinal(value: Value) {
        finalizePreliminaryValue()
        add(value: value)
        lastValueIsPreliminary = false
    }

    /// Add a preliminary value.
    /// If there currently is a preliminary value, it will be finalized (instead of being removed).
    public func addPreliminary(value: Value) {
        finalizePreliminaryValue()
        add(value: value)
        lastValueIsPreliminary = true
    }

    /// Mark the current preliminary value, if existing, as final.
    public func finalizePreliminaryValue() {
        lastValueIsPreliminary = false
    }

    /// Remove the preliminary value if existing.
    public func removePreliminaryValue() {
        if lastValueIsPreliminary {
            removeLast()
        }

        lastValueIsPreliminary = false
    }

    /// Convenience method to update the current preliminary value, which consists of removing and adding the preliminary value.
    public func updatePreliminary(value: Value) {
        removePreliminaryValue()
        addPreliminary(value: value)
    }

    /// Convenience method to update or create the current preliminary value if it is valid given the tolerance. The tolerance fallback is `.valid`.
    /// If the value is not valid, the preliminary value will be cleared.
    public func updatePreliminaryValueIfValid(value: Value) {
        removePreliminaryValue()
        if isValueValid(value) {
            addPreliminary(value: value)
        }
    }
}
