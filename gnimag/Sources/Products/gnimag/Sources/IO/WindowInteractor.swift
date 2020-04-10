//
//  Created by David Knothe on 10.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import Image
import Tapping

/// WindowInteractor bundles image-providing and tapping functionality for a specific macOS window.
final class WindowInteractor {
    private let window: Window

    /// Set to `true` to remove the top border (i.e. 22px) of the image, both for image providing and tapping.
    var removeUpperWindowBorder = false
    private let topWindowBorder: CGFloat = 22

    /// Default initializer.
    /// The given window must be running and onscreen.
    init(appName: String, windowNameHint: String? = nil) {
        window = WindowHelper.window(forApp: appName, windowNameHint: windowNameHint)
        makeApplicationFrontmost()
    }

    /// Bring the application owning the window to front.
    private func makeApplicationFrontmost() {
        let app = NSRunningApplication(processIdentifier: window.ownerPID)!
        app.activate(options: .activateIgnoringOtherApps)
    }

    /// An image provider providing the content of the window.
    lazy var imageProvider = DisplayLinkedImageProvider {
        CGWindowListCreateImage(self.absoluteWindowFrame, .optionIncludingWindow, self.window.windowID, .boundsIgnoreFraming)!
    }

    /// A tapper tapping on the window.
    lazy var tapper = MouseTapper { self.absoluteWindowFrame }

    /// A dragger moving the mouse on the window.
    lazy var dragger = MouseDragger { self.absoluteWindowFrame }

    /// The absolute frame of the window considering `removeUpperWindowBorder`, in ULO coordinates.
    private var absoluteWindowFrame: CGRect {
        if removeUpperWindowBorder {
            return WindowHelper.frame(of: window)
                .insetBy(dx: 0, dy: topWindowBorder / 2)
                .offsetBy(dx: 0, dy: topWindowBorder / 2)
        } else {
            return WindowHelper.frame(of: self.window)
        }
    }
}

// MARK: WindowHelper

private struct Window {
    let windowID: CGWindowID
    let ownerPID: Int32
}

/// WindowHelper provides helper methods for interacting with macOS windows.
private enum WindowHelper {
    /// Get the window ID of a window of a given application.
    /// The app must be running and have a single on-screen window whose name contains the windowNameHint.
    static func window(forApp appName: String, windowNameHint: String? = nil) -> Window {
        let info = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as! [[String: Any]]

        let windows = info.filter {
            ($0["kCGWindowOwnerName"] as? String) == appName &&
            (windowNameHint == nil || ($0["kCGWindowName"] as? String ?? "").contains(windowNameHint!))
        }

        switch windows.count {
        case ...0:
            exit(withMessage: "No window found for the desired application \"\(appName)\"")
        case 1:
            ()
        default: // (case 2...)
            let windowNames = windows.map { $0["kCGWindowName"] as? String ?? " " }
            exit(withMessage: "More than one window found for the desired application \"\(appName)\". (\(windowNames.joined(separator: ", ")))")
        }

        let window = windows.first!
        return Window(
            windowID: window["kCGWindowNumber"] as! CGWindowID,
            ownerPID: window["kCGWindowOwnerPID"] as! Int32
        )
    }

    /// Get the frame of a given window on the screen.
    /// The frame is in ULO coordinates, i.e. (0,0) is in the upper left corner.
    static func frame(of window: Window) -> CGRect {
        let windowInfo = CGWindowListCopyWindowInfo(.optionIncludingWindow, window.windowID)! as NSArray
        let window = windowInfo[0] as! NSDictionary
        return CGRect(dictionaryRepresentation: window["kCGWindowBounds"] as! NSDictionary)!
    }
}
