//
//  Created by David Knothe on 15.03.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

/// PrismStateTracker keeps track of the prism's state.
/// Thereby, it knows when the state should change (due to scheduled taps) and informs outsiders when this does or does not happen.
final class PrismStateTracker {
    private var state: PrismState?

    /// The state change between last frame and now.
    /// Nil if there is no change between last frame and now, else the new state.
    private(set) var stateChange: PrismState?

    /// Update the tracker with the new PrismState.
    /// This updates `stateChange`. Calling `update` again overrides `stateChange`.
    func update(with state: PrismState) {
        defer { self.state = state }
        if state != self.state {
            stateChange = state
        } else {
            stateChange = nil
        }
    }

    // ...
}
