//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Geometry
import Foundation

/// MouseControl can perform macOS mouse actions on the screen.
/// In this class, all absolute screen locations are in ULO coordinates, meaning (0,0) is in the upper left corner.
enum MouseControl {
    /// Perform a click (tap and release) on an absolute screen location.
    static func click(at point: CGPoint) {
        move(to: point)
        tap(at: point)
        release(at: point)
    }

    /// Perform a tap (but not a release) on an absolute screen location.
    static func tap(at point: CGPoint) {
        let tap = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left)!
        tap.post(tap: .cghidEventTap)
    }

    /// Perform a release on an absolute screen location.
    static func release(at point: CGPoint) {
        let release = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left)!
        release.post(tap: .cghidEventTap)
    }

    /// Move the mouse instantaneously to an absolute screen location.
    /// Attention: this is not a drag action, i.e. the mouse must not be tapped/down during a move action.
    static func move(to point: CGPoint) {
        let move = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left)!
        move.post(tap: .cghidEventTap)
    }

    /// Perform a drag action, i.e. move from start to end with a clicked mouse.
    /// Do not perform a tap nor a release. This must be done additionally.
    /// Realistic means: send drag events to multiple points on the way (which all have the same distance), and delay between them.
    /// Attention: this is synchronous, i.e. blocks until the drag was performed.
    static func realisticDrag(from start: CGPoint, to end: CGPoint, stepLength: CGFloat, stepDuration: CGFloat) {
        let dragStart = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDragged, mouseCursorPosition: start, mouseButton: .left)!
        dragStart.post(tap: .cghidEventTap)

        let length = start.distance(to: end)

        // Adjust stepDuration if number of steps in non-integer
        let fractionalSteps = length / stepLength
        let stepDuration = stepDuration * fractionalSteps / ceil(fractionalSteps)
        let numSteps = Int(ceil(fractionalSteps))

        for i in 1 ... numSteps {
            usleep(UInt32(1e6 * stepDuration))
            let progress = CGFloat(i) / CGFloat(numSteps)
            let location = start + progress * (end - start)

            // Send drag event
            let drag = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDragged, mouseCursorPosition: location, mouseButton: .left)!
            drag.post(tap: .cghidEventTap)
        }
    }

    /// Perform a drag action, i.e. move from start to end with a clicked mouse.
    /// Do not perform a tap nor a release. This must be done additionally.
    /// Instantaneous means: send drag events only to the start and end location, and delay between and after them.
    /// Attention: this is synchronous, i.e. blocks until the drag was performed.
    static func instantaneousDrag(from start: CGPoint, to end: CGPoint, delayBeforeDrag: Double, delayAfterDrag: Double) {
        let dragStart = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDragged, mouseCursorPosition: start, mouseButton: .left)!
        dragStart.post(tap: .cghidEventTap)

        usleep(UInt32(1e6 * delayBeforeDrag))

        let dragEnd = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDragged, mouseCursorPosition: end, mouseButton: .left)!
        dragEnd.post(tap: .cghidEventTap)

        usleep(UInt32(1e6 * delayAfterDrag))
    }
}
