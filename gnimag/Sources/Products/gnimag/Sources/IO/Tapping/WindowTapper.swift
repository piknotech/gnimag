//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Cocoa
import Tapping

/// An implementation of Tapper that clicks on the center of an arbitrary macOS application.
class WindowTapper: Tapper {
    /// The ID that corresponds to the desired window of the application.
    private let window: Window

    /// Default initializer.
    /// The app must be running and have an on-screen window.
    /// Automatically brings the app's windows to front.
    init(appName: String, windowNameHint: String? = nil) {
        window = WindowHelper.window(forApp: appName, windowNameHint: windowNameHint)

        makeApplicationFrontmost()
        centerMouse()
    }

    /// Bring the application owning the window to front.
    private func makeApplicationFrontmost() {
        let app = NSRunningApplication(processIdentifier: window.ownerPID)!
        app.activate(options: .activateIgnoringOtherApps)
    }

    /// Move the mouse to the window center.
    /// This is required for the first click to be as fast as the following ones.
    private func centerMouse() {
        let frame = WindowHelper.frame(of: window)
        let center = CGPoint(x: frame.midX, y: frame.midY)
        MouseControl.move(to: center)
    }

    /// Tap on the center of the window.
    func tap() {
        let frame = WindowHelper.frame(of: window)
        let center = CGPoint(x: frame.midX, y: frame.midY)
        MouseControl.click(at: center)
    }
}
