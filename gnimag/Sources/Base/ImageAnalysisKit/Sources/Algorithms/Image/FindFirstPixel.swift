//
//  Created by David Knothe on 27.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Image

/// FindFirstPixel searches for a single pixel with a given color.
extension Image {
    /// Find the first pixel matching the given color match on the given path.
    public func findFirstPixel(matching match: ColorMatch, on path: inout PixelPath) -> Pixel? {
        while let pixel = path.next() {
            if match.matches(color(at: pixel)) {
                return pixel
            }
        }

        return nil
    }
}
