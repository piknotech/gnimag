//
//  Created by David Knothe on 27.07.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Image

/// PixelPath describes a (not necessarily finite) sequence of pixels.
open class PixelPath: Sequence, IteratorProtocol {
    public typealias Element = Pixel
    public typealias Iterator = PixelPath

    /// Proceed to the next pixel of the path and return it.
    /// Once the path has finished and no more pixels are available, return nil on each subsequent call.
    open func next() -> Pixel? { nil }
}
