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
        let window = windows.first!
        windowID = window["kCGWindowNumber"] as! CGWindowID

        // Start display link
        CVDisplayLinkCreateWithCGDisplay(CGMainDisplayID(), &displayLink)
        CVDisplayLinkSetOutputHandler(displayLink!, displayLinkFire)
    }

    /// Capture the current window content.
    var currentImage: CGImage {
        return CGWindowListCreateImage(.zero, .optionIncludingWindow, windowID, .boundsIgnoreFraming)!
    }

    /// Called each time the display link fires.
    private func displayLinkFire(_: CVDisplayLink, _: UnsafePointer<CVTimeStamp>, _: UnsafePointer<CVTimeStamp>, _: CVOptionFlags, _: UnsafeMutablePointer<CVOptionFlags>) -> CVReturn {
        // Get image and call block (on same thread)
        let image = NativeImage(currentImage)
        let time = CACurrentMediaTime()
        newImage.trigger(with: (image, time))

        return 0
    }
}
