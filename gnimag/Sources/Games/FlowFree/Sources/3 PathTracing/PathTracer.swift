//
//  Created by David Knothe on 31.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import Tapping

/// PathTracer uses the screen layout to draw level solutions.
class PathTracer {
    private let underlyingDrawer: StraightLineMover

    /// The screen layout. Before using PathTracer, this must be set from outside.
    var screen: ScreenLayout!

    /// Default initializer.
    init(underlyingDrawer: StraightLineMover) {
        self.underlyingDrawer = underlyingDrawer
    }

    /// Draw the solution to a level onto the screen.
    /// Returns a promise which is fulfilled once the solution was fully drawn.
    func draw(solution: Solution, to level: Level) -> Promise<Void> {
        return .success()
    }
}
