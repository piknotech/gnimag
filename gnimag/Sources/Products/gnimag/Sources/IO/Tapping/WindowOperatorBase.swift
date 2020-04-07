//
//  Created by David Knothe on 01.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Cocoa

/// WindowOperatorBase bundles some methods that are useful for all on-window mouse operations.
class WindowOperatorBase {
    /// The ID that corresponds to the desired window of the application.
    let window: Window

    /// Default initializer.
    /// The app must be running and have an on-screen window.
    /// Automatically brings the app's windows to front.
    init(appName: String, windowNameHint: String? = nil) {
        window = WindowHelper.window(forApp: appName, windowNameHint: windowNameHint)

        makeApplicationFrontmost()
        setup()
    }

    /// Bring the application owning the window to front.
    private func makeApplicationFrontmost() {
        let app = NSRunningApplication(processIdentifier: window.ownerPID)!
        app.activate(options: .activateIgnoringOtherApps)
    }

    /// Override to perform further setup.
    /// The application was already ordered to front.
    func setup() {
    }

    /// Convert the given relative location (in 0..1 x 0..1) to an absolute screen location.
    func convert(fromRelativeLocation point: CGPoint) -> CGPoint {
        let frame = WindowHelper.frame(of: window)
        let x = frame.origin.x + point.x * frame.width
        let y = frame.origin.y + frame.height * (1-point.y) // LLO
        return CGPoint(x: x, y: y)
    }
}
