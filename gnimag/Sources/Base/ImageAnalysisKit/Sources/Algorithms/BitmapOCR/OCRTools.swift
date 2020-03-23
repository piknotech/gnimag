//
//  Created by David Knothe on 23.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation
import Image

internal enum OCRTools {
    enum ConnectivityType {
        /// Diagonal pixels are not considered neighbors.
        /// Each (non-edge) pixel has four neighbors.
        case four

        /// Diagonal pixels are considered neighbors.
        /// Each (non-edge) pixel has eight neighbors.
        case eight
    }

    /// Extract connected components from an image. Then, combine components using a combine decision function.
    static func components(in image: Image, textColor: ColorMatch, connectivity: ConnectivityType, combineComponents: (OCRComponent, OCRComponent) -> Bool) -> [OCRComponent] {
        []
    }
}
