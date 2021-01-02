//
//  Created by David Knothe on 01.04.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Foundation
import Tapping

/// An implementation of Dragger that performs move and drag actions with the macOS mouse.
class MouseDragger: Dragger {
    /// The frame determines the absolute location of the full interaction region on the screen, in ULO coordinates.
    fileprivate let getFrame: () -> CGRect

    /// Default initializer.
    init(getFrame: @escaping () -> CGRect) {
        self.getFrame = getFrame
    }

    // MARK: Configuration

    /// The dragging configuration. You can change it from outside.
    var configuration = Configuration(
        draggingType: .realistic(stepLength: 190, stepDuration: 0.06),
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


    // MARK: Dragger

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

    /// Convert the given relative (LLO) location (in 0..1 x 0..1) to an absolute screen location.
    private func convert(fromRelativeLocation point: CGPoint) -> CGPoint {
        let frame = getFrame()
        let x = frame.origin.x + point.x * frame.width
        let y = frame.origin.y + frame.height * (1-point.y) // LLO to ULO
        return CGPoint(x: x, y: y)
    }
}
