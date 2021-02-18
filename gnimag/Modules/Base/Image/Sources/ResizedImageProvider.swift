//
//  Created by David Knothe on 18.02.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Foundation

/// An `ImageProvider` which resizes images coming from another `ImageProvider`.
public final class ResizedImageProvider: ImageProvider {
    private let imageProvider: ImageProvider

    /// Create a ResizedImageProvider using a resizing closure.
    private init(imageProvider: ImageProvider, resize: @escaping (Image) -> Image) {
        self.imageProvider = imageProvider

        imageProvider.newFrame += { (image, time) in
            self.newFrame.trigger(with: (resize(image), time))
        }
    }

    /// Create a ResizedImageProvider using a factor for resizing.
    public convenience init(imageProvider: ImageProvider, resizeToFactor factor: CGFloat) {
        self.init(imageProvider: imageProvider) { $0.resize(factor: factor) }
    }

    /// Create a ResizedImageProvider using a CGSize for resizing.
    public convenience init(imageProvider: ImageProvider, resizeTo size: CGSize) {
        self.init(imageProvider: imageProvider) { $0.resize(to: size) }
    }

    public let newFrame = Event<Frame>()

    public var timeProvider: TimeProvider {
        imageProvider.timeProvider
    }
}

extension ImageProvider {
    public func resizingImages(to size: CGSize) -> ImageProvider {
        ResizedImageProvider(imageProvider: self, resizeTo: size)
    }

    public func resizingImages(factor: CGFloat) -> ImageProvider {
        ResizedImageProvider(imageProvider: self, resizeToFactor: factor)
    }
}
