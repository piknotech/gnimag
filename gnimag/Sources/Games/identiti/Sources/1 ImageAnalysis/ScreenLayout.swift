//
//  Created by David Knothe on 21.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Geometry

/// The exact layout of elements on the screen.
/// Useful for both image analysis and tapping.
struct ScreenLayout {
    let upperTermBox: AABB
    let lowerTermBox: AABB

    let equalButton: Circle
    let notEqualButton: Circle
}
