//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common

/// You can subscribe to an ImageProvider to receive updates each time a new image is available.
public protocol ImageProvider {
    typealias Time = Double

    /// The event that is called each time a new image is available.
    var newImage: Event<(Image, Time)> { get }
}
