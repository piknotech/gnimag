//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Image
import Tapping

/// Scrcpy provides input and output classes if you want to use the scrcpy application to communicate with an Android device.
let scrcpy = WindowInteractor(appName: "scrcpy").with {
    $0.removeUpperWindowBorder = true
}

// MARK: Withable

extension WindowInteractor: Withable { }
private protocol Withable { }

extension Withable {
    @discardableResult
    func with(_ block: (inout Self) -> Void) -> Self {
        var copy = self
        block(&copy)
        return copy
    }
}
