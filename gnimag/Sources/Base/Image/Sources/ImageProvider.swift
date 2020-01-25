//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common

/// You can subscribe to an ImageProvider to receive updates each time a new image is available.
public protocol ImageProvider {
    typealias Time = Double
    typealias Frame = (Image, Time)

    /// The event that is called each time a new frame is available.
    /// The time in the event can be different from the event trigger time (because of image copying or other preparation operations).
    var newFrame: Event<Frame> { get }

    /// Return the precise current time.
    /// Must be consistent (same time-source) with time used in `newFrame`.
    var time: Time { get }
}
