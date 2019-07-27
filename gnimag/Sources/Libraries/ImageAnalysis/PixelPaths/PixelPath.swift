//
//  Created by David Knothe on 27.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Input

/// PixelPath describes a sequence of arbitrary many pixels.
/// The path can be retrieved sequentially, each time as many pixels as desired.

public protocol PixelPath {
    /// Return the specified amount of pixels following in the path.
    /// If the walk ends during this request, cut the array so it contains between 0 and num-1 elements.
    mutating func next(_ num: Int) -> [Pixel]
}
