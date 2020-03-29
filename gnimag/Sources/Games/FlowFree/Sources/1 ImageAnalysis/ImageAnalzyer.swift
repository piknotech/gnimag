//
//  Created by David Knothe on 29.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Geometry
import Image
import ImageAnalysisKit

/// ImageAnalyzer extracts levels from images.
class ImageAnalyzer {
    /// The ScreenLayout which is available after the first successful `analyze` call.
    private(set) var screen: ScreenLayout!

    /// Analyze an image; return the level.
    /// Returns nil if no board or valid level is found in the image.
    func analyze(image: Image) -> Level? {
        nil
    }
}
