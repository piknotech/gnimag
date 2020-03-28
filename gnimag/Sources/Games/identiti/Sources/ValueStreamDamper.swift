//
//  Created by David Knothe on 27.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common

/// Consider a value stream where a value change triggers an action, but value changes only happen every few frames at most (i.e. in the meantime the same value is sent each frame).
/// ValueStreamDamper can be used to dismiss erroneous values in the value stream, i.e. values that erroneously appear only for a single frame and do not actually belong into the stream (which would trigger erroneous actions to be performed).
/// ValueStreamDamper requires a new value to be received at least 3 (e.g.) times in a row before triggering the value change action; values which appear just once or twice are dismissed.
struct ValueStreamDamper<T: Equatable> {
    /// The event which is triggered when a valid (i.e. non-erroneous) value change was detected.
    let newValue = Event<T?>()

    /// The number of times the same value has to be received in a row for a successful value change.
    private let numberOfConsecutiveValues: Int

    /// When the value which is sent is `nil`, a different required consecutivity number can be set; i.e.:
    /// The number of times a `nil` value has to be received in a row for a successful value change (to `nil`).
    /// Nil values are treated just like any other value.
    private let numberOfConsecutiveNilValues: Int

    /// The currently active value.
    /// Is `nil` at the beginning.
    private var currentValue: T?

    /// The new value which is currently being decided about.
    /// Is .none when no value is currently decided about; is .some(.none) when it is currently decided about a `nil` value.
    private var newValueInQuestion: T??

    /// The number of times the new value was added consecutively. If this reaches the required threshold, the `newValue` event is triggered.
    private var consecutiveNewValues = 0

    /// Default initializer.
    init(numberOfConsecutiveValues: Int, numberOfConsecutiveNilValues: Int? = nil) {
        self.numberOfConsecutiveValues = numberOfConsecutiveValues
        self.numberOfConsecutiveNilValues = numberOfConsecutiveNilValues ?? numberOfConsecutiveValues
    }

    /// Add a value to the value stream.
    /// This will trigger the value change event if required.
    mutating func add(value: T?) {
        if value == currentValue { // Same value, nothing TBD
            consecutiveNewValues = 0
            newValueInQuestion = .none
            return
        }

        // Increase `consecutiveNewValues`
        if let inQuestion = newValueInQuestion, value == inQuestion { // Current value in question
            consecutiveNewValues += 1
        } else { // New value in question
            consecutiveNewValues = 1
        }
        newValueInQuestion = value

        // Check whether a new value event should be triggered
        if value == nil && consecutiveNewValues >= numberOfConsecutiveNilValues ||
            value != nil && consecutiveNewValues >= numberOfConsecutiveValues {
            consecutiveNewValues = 0
            newValueInQuestion = .none
            currentValue = value
            newValue.trigger(with: currentValue)
        }
    }
}
