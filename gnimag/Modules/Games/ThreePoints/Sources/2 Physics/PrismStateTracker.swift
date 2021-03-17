//
//  Created by David Knothe on 15.03.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

/// PrismStateTracker keeps track of the prism's state.
/// Thereby, it knows when the state should change (due to scheduled taps) and informs outsiders when this does or does not happen.
final class PrismStateTracker {
    /// The current state and top color.
    private(set) var state = Change<PrismState>()
    private(set) var color = Change<DotColor>()

    /// Update the tracker with the new PrismState.
    /// This updates `stateChange`. Calling `update` again overrides `stateChange`.
    func update(with newState: PrismState) {
        state.set(value: newState)
        color.set(value: newState.topColor)

        if color.change != nil { print(color.value!) }
    }
}

struct Change<A: Equatable> {
    private(set) var value: A?
    private(set) var change: A?

    init(initialValue: A? = nil) {
        value = nil
    }

    mutating func set(value: A) {
        defer { self.value = value }
        if [nil, value].contains(self.value) {
            change = nil
        } else {
            change = value
        }
    }
}
