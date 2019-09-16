//
//  Created by David Knothe on 27.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Image

/// FindFirstPixel searches for a single pixel with a given color.
extension Image {
    /// Find the first pixel matching the given color match on the given path.
    public func findFirstPixel(matching match: ColorMatch, on path: PixelPath) -> Pixel? {
        path.first { match.matches(color(at: $0)) }
    }

    /// Go along the path until the color match is not fulfilled anymore; return the last pixel which still fulfilled it.
    /// If the first pixel does not fulfill the match, return nil.
    /// If all pixels on the path fulfill the match, return nil.
    public func findLastPixel(matching match: ColorMatch, on path: PixelPath) -> Pixel? {
        let candidate = path.prefix { match.matches(color(at: $0)) }.last
        return candidate.flatMap {
            match.matches(color(at: $0)) ? candidate : nil // If all pixels fulfilled the match, also return nil
        }
    }
}
