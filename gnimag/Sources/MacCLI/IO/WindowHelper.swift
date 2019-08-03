//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

/// WindowHelper provides helper methods for both image input and tapping.
enum WindowHelper {
    /// Get the window ID of a window of a given application.
    /// The app must be running and have a single on-screen window whose name contains the windowNameHint.
    static func mainWindowID(forApp appName: String, windowNameHint: String = "") -> CGWindowID {
        let info = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as! [[String: Any]]
        let windows = info.filter {
            ($0["kCGWindowOwnerName"] as! String) == appName &&
            ($0["kCGWindowName"] as! String).contains(windowNameHint)
        }

        switch windows.count {
        case ...0:
            fatalError("No window found for the desired application \"\(appName)\"")
        case 1:
            ()
        default: // (case 2...)
            fatalError("More than one window found for the desired application \"\(appName)\"")
        }

        let window = windows.first!
        return window["kCGWindowNumber"] as! CGWindowID
    }

    /// Get the frame of a given window on the screen.
    static func frameOfWindow(withID id: CGWindowID) -> CGRect {
        let windowInfo = CGWindowListCopyWindowInfo(.optionIncludingWindow, id)! as NSArray
        let window = windowInfo[0] as! NSDictionary
        return CGRect(dictionaryRepresentation: window["kCGWindowBounds"] as! NSDictionary)!
    }
}
