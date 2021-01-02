//
//  Created by David Knothe on 02.01.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Foundation
import IOKit.pwr_mgt

enum PowerManager {
    private static var assertionID: IOPMAssertionID = 0

    /// Disable the screen from going to sleep.
    /// This might be required for an instance of gnimag, e.g. when it mirrors the device to the screen and therefore needs the screen to stay on.
    /// Only call once.
    static func disableScreenSleep() {
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "gnimag requires the screen to permanently stay on to read the mirrored device" as CFString,
            &assertionID
        )

        if result != kIOReturnSuccess {
            exit(withMessage: "Couldn't create display-on assertion. This is required to keep the display on as long as gnimag is running.")
        }
    }
}
