//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation
import Tapping

/// An implementation of Tapper and ArbitraryLocationTapper that clicks on the macOS screen.
class MouseTapper {
    /// The frame determines the absolute location of the full interaction region on the screen, in ULO coordinates.
    fileprivate let getFrame: () -> CGRect

    /// Default initializer.
    /// Center mouse on initialization.
    init(getFrame: @escaping () -> CGRect) {
        self.getFrame = getFrame
        centerMouse()
    }

    /// Move the mouse to the window center.
    /// This is required for the first click to be as fast as the following ones.
    private func centerMouse() {
        let frame = getFrame()
        let center = CGPoint(x: frame.midX, y: frame.midY)
        MouseControl.move(to: center)
    }
}

extension MouseTapper: Tapper {
    /// Tap on the center of the window.
    func tap() {
        let frame = getFrame()
        let center = CGPoint(x: frame.midX, y: frame.midY)
        MouseControl.click(at: center)
    }
}

extension MouseTapper: ArbitraryLocationTapper {
    /// Convert the given relative (LLO) location (in 0..1 x 0..1) to an absolute screen location.
    private func convert(fromRelativeLocation point: CGPoint) -> CGPoint {
        let frame = getFrame()
        let x = frame.origin.x + point.x * frame.width
        let y = frame.origin.y + frame.height * (1-point.y) // LLO to ULO
        return CGPoint(x: x, y: y)
    }

    /// Tap on the given relative location (LLO) on the window.
    func tap(at point: CGPoint) {
        let absolute = convert(fromRelativeLocation: point)
        MouseControl.click(at: absolute)
    }
}
