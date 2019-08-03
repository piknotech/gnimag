//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Cocoa
import ImageInput

/// ImageListProvider provides a list of images in a folder, one by one, with a user-defined framerate.
/// The images are sorted and must be of the form "1.png", "2.png", etc.
internal class ImageListProvider: ImageProvider {
    /// The folder path.
    private let folderPath: String

    /// The current image.
    private var i = 0

    /// The framerate with which images are provided.
    private let framerate: Int

    /// The timer firing the callback block.
    private var timer: Timer?

    /// The event that is called each time a new image is available.
    var newImage = Event<(Image, Time)>()

    /// Default initializer.
    init(folderPath: String, framerate: Int) {
        self.folderPath = folderPath
        self.framerate = framerate
    }

    /// Return the next image in the folder.
    private var nextImage: CGImage? {
        i += 1
        let path = folderPath + "/\(i).png"
        print("image: \(i)")

        if let image = NSImage(contentsOfFile: path)?.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            return image
        } else {
            // All images consumed
            pause()
            return nil
        }
    }

    /// Start or continue providing images.
    func start() {
        pause()

        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / Double(framerate), repeats: true) { _ in
            let time = Double(self.i) / Double(self.framerate)
            if let image = self.nextImage {
                self.newImage.trigger(with: (NativeImage(image), time))
            }
        }
    }

    /// Pause providing images.
    func pause() {
        timer?.invalidate()
        timer = nil
    }
}
