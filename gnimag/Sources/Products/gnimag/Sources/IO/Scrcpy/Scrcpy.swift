//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Image
import Tapping

/// Scrcpy provides input and output classes if you want to use the scrcpy application to communicate with an Android device.
let scrcpy = WindowInteractor(appName: "scrcpy").with {
    $0.removeUpperWindowBorder = true
}

extension WindowInteractor: Withable { }
