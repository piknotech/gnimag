//
//  Created by David Knothe on 01.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import Tapping

/// An implementation of Dragger that performs move and drag actions on the window of an arbitrary macOS application.
class WindowDragger: WindowOperatorBase, Dragger {
    /// The dragging configuration. You can change it from outside.
    var configuration = Configuration(
        draggingType: .realistic(stepLength: 150, stepDuration: 0.06),
        delayAfterTap: 0.1
    )

    struct Configuration {
        enum DraggingType {
            /// Sends drag events to multiple points on the way (which all have the same distance), and delays between them.
            case realistic(stepLength: CGFloat, stepDuration: CGFloat)

            /// Sends drag events only to the start and end location, and delays between and after them.
            case instantaneous(delayBeforeDrag: Double, delayAfterDrag: Double)
        }

        /// The way the macOS mouse is dragged.
        /// Small delays are required for macOS to correctly send and process consecutive dragging events.
        let draggingType: DraggingType

        /// The delay after a tap (without a release) action.
        let delayAfterTap: Double
    }

    /// The current position of the cursor, in absolute coordinates.
    private var currentPosition: CGPoint!

    /// True if the mouse is currently down; false if it is released.
    private var mouseDown = false

    /// Tap down at the current location.
    /// Attention: this is synchronous, i.e. blocks until the tap was performed.
    func down() -> Promise<Void> {
        mouseDown = true
        MouseControl.tap(at: currentPosition)
        usleep(UInt32(1e6 * configuration.delayAfterTap))
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
            // Perform drag
            switch configuration.draggingType {
            case let .instantaneous(delayBeforeDrag: delayBeforeDrag, delayAfterDrag: delayAfterDrag):
                MouseControl.instantaneousDrag(from: currentPosition, to: destination, delayBeforeDrag: delayBeforeDrag, delayAfterDrag: delayAfterDrag)

            case let .realistic(stepLength: stepLength, stepDuration: stepDuration):
                MouseControl.realisticDrag(from: currentPosition, to: destination, stepLength: stepLength, stepDuration: stepDuration)
            }
        } else {
            // Move the mouse
            MouseControl.move(to: destination)
        }

        return .success()
    }
}
