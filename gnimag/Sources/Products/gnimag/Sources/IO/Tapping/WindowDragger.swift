//
//  Created by David Knothe on 01.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import Tapping

/// An implementation of Dragger that performs move and drag actions on the window of an arbitrary macOS application.
class WindowDragger: WindowOperatorBase, Dragger {
    /// The current position of the cursor, in absolute coordinates.
    private var currentPosition: CGPoint!

    /// True if the mouse is currently down; false if it is released.
    private var mouseDown = false

    /// Tap down at the current location.
    /// Attention: this is synchronous, i.e. blocks until the tap was performed.
    func down() -> Promise<Void> {
        mouseDown = true
        MouseControl.tap(at: currentPosition)
        usleep(100_000) // Helpful in conjunction with drag actions
        return .success()
    }

    /// Release the current tap if existing.
    func up() {
        mouseDown = false
        MouseControl.release(at: currentPosition)
    }

    /// Move or drag to the given location.
    /// Attention: this is synchronous, i.e. blocks until the drag was performed.
    func move(to point: CGPoint) -> Promise<Void> {
        let destination = convert(fromRelativeLocation: point)
        defer { currentPosition = destination }

        if mouseDown {
            return MouseControl.realisticDrag(from: currentPosition, to: destination)
        } else {
            MouseControl.move(to: destination)
            return .success()
        }
    }
}
