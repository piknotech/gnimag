//
//  Created by David Knothe on 29.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Image

/// OnOffImageProvider is a wrapper around an image provider which simply forwards the received images.
/// You can, however, call `pause` to begin discarding any images that are received from now on until calling `continue`.
/// Images which are received in the meantime are discarded and not forwarded. They cannot be recovered lateron.
public class OnOffImageProvider: ImageProvider {
    private let wrapped: ImageProvider
    public var timeProvider: TimeProvider { wrapped.timeProvider }

    /// The event which is forwarded from the wrapped image provider.
    public let newFrame = Event<Frame>()

    /// States whether incoming images should be forwarded.
    private var running = true

    /// Default initializer.
    /// By default, images are forwarded, i.e. there is no need to call `continue` before calling `pause`.
    public init(wrapping provider: ImageProvider) {
        wrapped = provider

        // Forward `newFrame` event
        wrapped.newFrame += {
            if self.running {
                self.newFrame.trigger(with: $0)
            }
        }
    }

    /// Pause forwarding images and discard all further incoming images.
    public func pause() {
        running = false
    }

    /// Continue forwarding images.
    public func `continue`() {
        running = true
    }
}
