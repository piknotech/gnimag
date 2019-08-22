//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Cocoa
import ImageInput

/// ImageListProvider provides a list of images in a directory, one by one, with a user-defined framerate.
/// The images are sorted and must be of the form "1.png", "2.png", etc. Use an ImageListCreator to easily create such a directory.
public final class ImageListProvider: ImageProvider {
    /// The directory path.
    private let directoryPath: String

    /// The next image to consume.
    private var i = 1

    /// The framerate with which images are provided.
    private let framerate: Int

    /// The timer firing the callback block.
    private var timer: Timer?

    /// The event that is called each time a new image is available.
    public var newImage = Event<(Image, Time)>()

    /// Conversion block from CGImages to Images.
    private let imageFromCGImage: (CGImage) -> Image

    /// Default initializer.
    /// Start providing images immediately.
    public init(directoryPath: String, framerate: Int, imageFromCGImage: @escaping (CGImage) -> Image) {
        self.directoryPath = directoryPath
        self.framerate = framerate
        self.imageFromCGImage = imageFromCGImage

        `continue`()
    }

    /// Return the next image in the directory.
    private var nextImage: CGImage? {
        let path = directoryPath + "/\(i).png"
        print("image: \(i)")

        if let image = NSImage(contentsOfFile: path)?.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            i += 1
            return image
        } else {
            // All images consumed
            pause()
            return nil
        }
    }

    /// Start or continue providing images.
    public func `continue`() {
        pause()

        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / Double(framerate), repeats: true) { _ in
            let time = Double(self.i) / Double(self.framerate)
            if let image = self.nextImage {
                self.newImage.trigger(with: (self.imageFromCGImage(image), time))
            }
        }
    }

    /// Pause providing images.
    public func pause() {
        timer?.invalidate()
        timer = nil
    }
}
