//
//  Created by David Knothe on 26.03.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Foundation

/// An AnywhereTapper can tap on any location on the phone screen.
/// Currently, there is no requirement or assumption for how long it takes the tapper to perform its task.
public protocol AnywhereTapper {
    /// Tap at the given relative (LLO) location, (0, 0) meaning lower left and (1, 1) meaning upper right.
    func tap(at point: CGPoint)
}

public extension AnywhereTapper {
    /// Convenience method to tap at a given location, expressed in coordinates respective to `screenSize` (i.e. inside a frame with origin (0,0) and size = screenSize).
    func tap(atAbsolute point: CGPoint, screenSize: CGSize) {
        let x = point.x / screenSize.width
        let y = point.y / screenSize.height
        tap(at: CGPoint(x: x, y: y))
    }
}
