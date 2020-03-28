//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Cocoa
import Common
import Image

/// ImageListProvider provides a list of images in a directory, one by one, with a user-defined framerate.
/// The images are sorted and must be of the form "1.png", "2.png", etc. Use an ImageListCreator to easily create such a directory.
public final class ImageListProvider: ImageProvider {
    /// The directory path.
    private let directoryPath: String

    /// The latest consumed image (1-based).
    private var i: Int
    private let speed: Int

    /// The framerate with which images are provided (in Hertz).
    private let framerate: Int

    /// The timer firing the callback block.
    private var timer: Timer?

    /// The event that is called each time a new image is available.
    public var newFrame = Event<Frame>()

    /// Conversion block from CGImages to Images.
    private let imageFromCGImage: (CGImage) -> Image

    /// Default initializer.
    /// Start providing images immediately.
    public init(directoryPath: String, framerate: Int, startingAt: Int = 1, speed: Int = 1, imageFromCGImage: @escaping (CGImage) -> Image = NativeImage.init) {
        self.directoryPath = directoryPath
        self.framerate = framerate
        self.imageFromCGImage = imageFromCGImage
        self.speed = speed
        i = startingAt - speed

        `continue`()
    }

    /// Return the current image (image number `i`) in the directory.
    private var currentImage: CGImage? {
        let path = directoryPath +/ "\(i).png"

        if let image = NSImage(contentsOfFile: path)?.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            Terminal.log(.info, "Image \(i)")
            return image
        } else {
            // All images consumed
            Terminal.log(.info, "ImageListProvider – finished")
            pause()
            return nil
        }
    }

    /// The current time, which is defined by the current image index.
    /// Attention: This is a synthetic, not an actual time value.
    public lazy var timeProvider = TimeProvider {
        Double(self.i) / Double(self.framerate * self.speed)
    }

    /// Start or continue providing images.
    public func `continue`() {
        guard timer == nil else { return }

        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / Double(framerate), repeats: true) { _ in
            self.i += self.speed // Next image
            let time = self.timeProvider.currentTime // Get current time before copying the image
            if let image = self.currentImage {
                self.newFrame.trigger(with: (self.imageFromCGImage(image), time))
            }
        }
    }

    /// Pause providing images.
    public func pause() {
        timer?.invalidate()
        timer = nil
    }
}
