//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Image
import Tapping

extension WindowInteractor: Withable { }

/// Scrcpy provides input and output classes if you want to use the scrcpy application to communicate with an Android device.
let scrcpy = WindowInteractor(appName: "scrcpy").with {
    $0.removeUpperWindowBorder = true
}

/// Vysor provides input and output classes if you want to use the Vysor application to communicate with an Android device.
func vysor(hint: String? = nil) -> WindowInteractor {
    WindowInteractor(appName: "Vysor", windowNameHint: hint)
}
