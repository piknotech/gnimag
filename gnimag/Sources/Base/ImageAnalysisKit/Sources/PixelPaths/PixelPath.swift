//
//  Created by David Knothe on 27.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Image

/// PixelPath describes a sequence of arbitrary many pixels.
/// The path can be retrieved sequentially, each time as many pixels as desired.
public protocol PixelPath {
    /// Proceed to the next pixel of the path and return it.
    /// Once the path has finished and no more pixels are available, return nil on each subsequent call.
    mutating func next() -> Pixel?
}
