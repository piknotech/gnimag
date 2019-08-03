//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import QuartzCore
import ImageInput

/// An implementation of ImageProvider using a macOS app and capturing it's window content.
/// The subscriber is notified in sync with the display update cycle.

class AppWindowScreenProvider: ImageProvider {
    /// The window ID that corresponds to the desired window of the application.
    private let windowID: CGWindowID

    /// The display link that triggers periodical callbacks.
    private var displayLink: CVDisplayLink?

    /// When true, 22px of the top of the image are removed.
    var removeUpperWindowBorder = false
    private let topWindowBorder = 22

    /// The event that is called each time a new image is available.
    var newImage = Event<(Image, Time)>()

    /// Default initializer.
    /// Precondition: the given app is running and onscreen.
    init(appName: String, windowNameHint: String! = nil) {
        // Get window ID
        let info = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as! [[String: Any]]
        let windows = info.filter {
            $0["kCGWindowOwnerName"] as! String == appName &&
                (windowNameHint == nil || ($0["kCGWindowName"] as! String).contains(windowNameHint))
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
        windowID = window["kCGWindowNumber"] as! CGWindowID

        // Start display link
        CVDisplayLinkCreateWithCGDisplay(CGMainDisplayID(), &displayLink)
        CVDisplayLinkSetOutputHandler(displayLink!, displayLinkFire)
    }

    /// Capture the current window content.
    var currentImage: CGImage {
        let image = CGWindowListCreateImage(.zero, .optionIncludingWindow, windowID, .boundsIgnoreFraming)!

        if removeUpperWindowBorder {
            return image.cropping(to: CGRect(x: 0, y: topWindowBorder, width: image.width, height: image.height - topWindowBorder))!
        } else {
            return image
        }
    }

    /// Called each time the display link fires.
    private func displayLinkFire(_: CVDisplayLink, _: UnsafePointer<CVTimeStamp>, _: UnsafePointer<CVTimeStamp>, _: CVOptionFlags, _: UnsafeMutablePointer<CVOptionFlags>) -> CVReturn {
        // Get image and call block (on same thread)
        let time = CACurrentMediaTime()
        let image = NativeImage(currentImage)
        newImage.trigger(with: (image, time))

        return 0
    }
}
