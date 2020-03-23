//
//  Created by David Knothe on 23.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Image
import Foundation

/// OCRComponent describes a component (i.e. a possible character or character part).
/// A component is inside a rectangular subregion of an image. The component consists of one or multiple pixels inside this subregion.
internal struct OCRComponent {
    /// The bounding region of this component, respective to the original image.
    /// This is the smallest rectangular region which contains all pixels of this component.
    let region: Bounds

    /// All pixels the component consists of.
    /// The pixel locations are relative to the original image, i.e. all pixels are inside `region`.
    let pixels: [Pixel]

    /// Combine this component with another one.
    func combine(with other: OCRComponent) -> OCRComponent {
        OCRComponent(
            region: Bounds(rect: region.CGRect.union(other.region.CGRect)),
            pixels: pixels + other.pixels
        )
    }
}
