//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common

/// You can subscribe to an ImageProvider to receive updates each time a new image is available.
public protocol ImageProvider {
    typealias Time = Double
    typealias Frame = (Image, Time)

    /// The event that is called each time a new frame is available.
    /// The time in the event can be different from the event trigger time (because of image copying or other preparation operations).
    var newFrame: Event<Frame> { get }

    /// A TimeProvider returning the precise current time.
    /// Use this timeProvider to obtain the time values that are used in `newFrame`.
    var timeProvider: TimeProvider { get }
}
