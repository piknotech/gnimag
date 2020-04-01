//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation
import Tapping

/// An implementation of Tapper and ArbitraryLocationTapper that clicks on the window of an arbitrary macOS application.
class WindowTapper: WindowOperatorBase {
    /// Center mouse on initialization.
    override func setup() {
        centerMouse()
    }

    /// Move the mouse to the window center.
    /// This is required for the first click to be as fast as the following ones.
    private func centerMouse() {
        let frame = WindowHelper.frame(of: window)
        let center = CGPoint(x: frame.midX, y: frame.midY)
        MouseControl.move(to: center)
    }
}

extension WindowTapper: Tapper {
    /// Tap on the center of the window.
    func tap() {
        let frame = WindowHelper.frame(of: window)
        let center = CGPoint(x: frame.midX, y: frame.midY)
        MouseControl.click(at: center)
    }
}

extension WindowTapper: ArbitraryLocationTapper {
    /// Tap on the given relative location (LLO) on the window.
    func tap(at point: CGPoint) {
        let absolute = convert(fromRelativeLocation: point)
        MouseControl.click(at: absolute)
    }
}
