//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Cocoa
import Foundation
import Tapping

/// An implementation of Tapper and ArbitraryLocationTapper that clicks on the window of an arbitrary macOS application.
class WindowTapper {
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
}

extension WindowTapper: Tapper {
    /// Tap on the center of the window.
    func tap() {
        let frame = WindowHelper.frame(of: window)
        let center = CGPoint(x: frame.midX, y: frame.midY)
        MouseControl.click(at: center)
    }
}

extension WindowTapper: ArbitraryLocationTapper {
    /// Tap on the given relative location (LLO) on the window.
    func tap(at point: CGPoint) {
        let absolute = convert(fromRelativeLocation: point)
        MouseControl.click(at: absolute)
    }

    /// Convert the given relative location (in 0..1 x 0..1) to an absolute screen location.
    fileprivate func convert(fromRelativeLocation point: CGPoint) -> CGPoint {
        let frame = WindowHelper.frame(of: window)
        let x = frame.origin.x + point.x * frame.width
        let y = frame.origin.y + frame.height * (1-point.y) // LLO
        return CGPoint(x: x, y: y)
    }
}

extension WindowTapper: StraightLineMover {
    // – Stored property in an extension
    static private var lastLocations = [ObjectIdentifier: CGPoint]()
    var lastLocation: CGPoint! {
        get { Self.lastLocations[ObjectIdentifier(self)] }
        set { Self.lastLocations[ObjectIdentifier(self)] = newValue }
    }

    /// Move to the given relative location (LLO) on the window.
    func move(to point: CGPoint) {
        let absolute = convert(fromRelativeLocation: point)
        MouseControl.move(to: absolute)
        lastLocation = absolute
    }

    func up() {
        MouseControl.release(at: lastLocation)
    }

    func down() {
        MouseControl.click(at: lastLocation)
    }
}
