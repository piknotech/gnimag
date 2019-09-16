//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import Tapping

/// An implementation of Tapper that clicks on the center of an arbitrary macOS application.
class WindowTapper: Tapper {
    /// The ID that corresponds to the desired window of the application.
    private let windowID: CGWindowID

    /// Default initializer.
    /// The app must be running and have an on-screen window.
    init(appName: String, windowNameHint: String? = nil) {
        windowID = WindowHelper.windowID(forApp: appName, windowNameHint: windowNameHint)
    }

    /// Tap on the center of the window.
    func tap() {
        let frame = WindowHelper.frameOfWindow(withID: windowID)
        let center = CGPoint(x: frame.midX, y: frame.midY)
        MouseControl.click(at: center)
    }
}
