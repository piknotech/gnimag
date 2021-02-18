//
//  Created by David Knothe on 06.08.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Cocoa
import Common
import Image

/// As a counterpart to ImageListProvider, this class is used to create a directory with enumerated images in the first place.
/// Create an ImageListCreator and link it to any existing ImageProvider; then, the ImageListCreator will take every image produced by the ImageProvider and save it to the specified directory.
public final class ImageListCreator {
    /// The directory path.
    private let directoryPath: String

    /// The image counter.
    private var i = 0
    private let skipRate: Int

    private var nextImage: Int {
        i / skipRate + 1
    }

    /// The maximum number of images to write.
    private let maxImages: Int

    /// Default initializer.
    public init(directoryPath: String, every skipRate: Int = 1, maxImages: Int = Int.max) {
        self.directoryPath = directoryPath
        self.skipRate = skipRate
        self.maxImages = maxImages

        try! FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)
    }

    /// Listen for images produced by the ImageProvider and save each image to the specified directory.
    /// Attention: The produced images MUST have attached CGImages.
    public func link(to provider: ImageProvider) {
        provider.newFrame += { (image, _) in
            if self.nextImage > self.maxImages { return }
            if !self.i.isMultiple(of: self.skipRate) { self.i += 1; return } // Only save every `skipRate`th image

            let path = self.directoryPath +/ "\(self.nextImage).png"
            image.CGImage.write(to: path)
            self.i += 1
        }
    }
}
