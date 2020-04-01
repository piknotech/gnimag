//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation

/// MouseControl can perform mouse actions on the screen.
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
    /// As this action is not instantaneous, return a promise which is fulfilled when the drag has finished. This promise never fails.
    static func drag(from start: CGPoint, to end: CGPoint) -> Promise<Void> {
        let promise = Promise<Void>()

        let dragStart = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDragged, mouseCursorPosition: start, mouseButton: .left)!
        dragStart.post(tap: .cghidEventTap)

        Timing.perform(after: 0.1) {
            let dragEnd = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDragged, mouseCursorPosition: end, mouseButton: .left)!
            dragEnd.post(tap: .cghidEventTap)

            Timing.perform(after: 0) {
                promise.finished(with: .result(()))
            }
        }

        return promise
    }
}
