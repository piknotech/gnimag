//
//  Created by David Knothe on 31.03.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Foundation

/// Dragger can perform move and drag actions in straight lines.
/// Thereby, it can either be on the screen (i.e. performing a drag action) or not on the screen (i.e. moving to another location).
public protocol Dragger {
    /// Tap down at the current location. Do not release the tap until `up` is called.
    /// Before calling `down` the first time, you MUST call `move(to:)`.
    /// Return a promise which succeeds after the tap was executed. The promise never fails.
    func down() -> Promise<Void>

    /// Release the current tap if existing.
    /// Before calling `up` the first time, you MUST call `move(to:)`.
    func up()

    /// Move or drag to the given relative (LLO) location, (0, 0) meaning lower left and (1, 1) meaning upper right.
    /// Thereby, do not change the up/down state.
    /// Return a promise which succeeds after the movement was executed. The promise never fails.
    func move(to point: CGPoint) -> Promise<Void>
}
