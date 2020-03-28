//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation

/// MouseControl can perform mouse actions on the screen.
enum MouseControl {
    static func move(to point: CGPoint) {
        /// Move the mouse instantaneously to an absolute screen location.
        let event = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left)!
        event.post(tap: .cghidEventTap)
    }

    /// Perform a click (tap and release) on an absolute screen location.
    static func click(at point: CGPoint) {
        let move = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left)!
        move.post(tap: .cghidEventTap)

        let tap = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left)!
        tap.post(tap: .cghidEventTap)

        let release = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left)!
        release.post(tap: .cghidEventTap)
    }
}
