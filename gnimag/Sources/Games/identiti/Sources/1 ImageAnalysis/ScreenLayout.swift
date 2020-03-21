//
//  Created by David Knothe on 21.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Geometry

/// The exact layout of elements on the screen.
/// Useful for both image analysis and tapping.
struct ScreenLayout {
    let upperEquationBox: AABB
    let lowerEquationBox: AABB

    let trueButton: Circle
    let falseButton: Circle
}
