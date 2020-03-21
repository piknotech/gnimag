//
//  Created by David Knothe on 06.08.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Cocoa
import Common
import Image

/// As a counterpart to ImageListProvider, this class is used to create a directory with enumerated images in the first place.
/// Create an ImageListCreator and link it to any existing ImageProvider; then, the ImageListCreator will take every image produced by the ImageProvider and save it to the specified directory.
public final class ImageListCreator {
    /// The directory path.
    private let directoryPath: String

    /// The next image to create (1-based).
    private var i = 1

    /// The maximum number of images to write.
    private let maxImages: Int

    /// Default initializer.
    public init(directoryPath: String, maxImages: Int = Int.max) {
        self.directoryPath = directoryPath
        self.maxImages = maxImages

        try! FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)
    }

    /// Listen for images produced by the ImageProvider and save each image to the specified directory.
    /// Attention: The produced images MUST have attached CGImages.
    public func link(to provider: ImageProvider) {
        provider.newFrame += { (image, _) in
            if self.i > self.maxImages { return }

            guard let cgImage = image.CGImage else {
                return Terminal.log(.error, "ImageListCreator – incoming image doesn't have a CGImage and therefore cannot be written to disk.")
            }

            let path = self.directoryPath +/ "\(self.i).png"
            cgImage.write(to: path)
            self.i += 1
        }
    }
}
