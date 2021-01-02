//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Foundation
import Image
import QuartzCore

/// An implementation of ImageProvider using a display link to periodically trigger a callback action which provides an image.
class DisplayLinkedImageProvider: ImageProvider {
    private var displayLink: CVDisplayLink!

    /// The block which is called to provide an image each frame.
    private let imageProviderBlock: () -> CGImage

    /// The event that is called each time a new image is available.
    var newFrame = Event<Frame>()

    /// Default initializer.
    /// Start providing images immediately.
    init(imageProviderBlock: @escaping () -> CGImage) {
        self.imageProviderBlock = imageProviderBlock
        
        CVDisplayLinkCreateWithCGDisplay(CGMainDisplayID(), &displayLink)
        CVDisplayLinkSetOutputHandler(displayLink, displayLinkFire)
        CVDisplayLinkStart(displayLink)
    }

    /// The current time.
    lazy var timeProvider = TimeProvider(CACurrentMediaTime)

    /// Called each time the display link fires.
    private func displayLinkFire(_: CVDisplayLink, _: UnsafePointer<CVTimeStamp>, _: UnsafePointer<CVTimeStamp>, _: CVOptionFlags, _: UnsafeMutablePointer<CVOptionFlags>) -> CVReturn {
        // Only get the image if there are subscribers
        if newFrame.hasSubscribers {
            let time = timeProvider.currentTime // Get current time before copying the image
            let image = NativeImage(imageProviderBlock())
            newFrame.trigger(with: (image, time))
        }

        return kCVReturnSuccess
    }
}
