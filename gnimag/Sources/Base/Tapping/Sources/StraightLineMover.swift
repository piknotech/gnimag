//
//  Created by David Knothe on 31.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation

/// StraightLineMover can move in straight lines.
/// Thereby, it can either be on the screen (i.e. performing a slide action) or not on the screen (i.e. moving to another location).
public protocol StraightLineMover {
    /// Tap down at the current location. Do not release the tap until `up` is called.
    /// Before calling `down` the first time, you MUST call `move(to:)`.
    func down()

    /// Release the current tap if existing.
    /// Before calling `up` the first time, you MUST call `move(to:)`.
    func up()

    /// Move to the given relative (LLO) location, (0, 0) meaning lower left and (1, 1) meaning upper right.
    /// Thereby, do not change the up/down state.
    func move(to point: CGPoint)
}
