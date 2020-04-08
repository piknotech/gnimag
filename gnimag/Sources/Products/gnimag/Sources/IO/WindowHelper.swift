//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation

struct Window {
    let windowID: CGWindowID
    let ownerPID: Int32
}

/// WindowHelper provides helper methods for both image input and tapping.
enum WindowHelper {
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
    static func frame(of window: Window) -> CGRect {
        let windowInfo = CGWindowListCopyWindowInfo(.optionIncludingWindow, window.windowID)! as NSArray
        let window = windowInfo[0] as! NSDictionary
        return CGRect(dictionaryRepresentation: window["kCGWindowBounds"] as! NSDictionary)!
    }
}
