//
//  Created by David Knothe on 06.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import Image

/// Implement this protocol for Mac-specific Images that you want to be able to use for BitmapCanvas or ImageListCreator.
public protocol ConvertibleToCGImage {
    /// Convert the instance to a CGImage.
    var CGImage: CGImage { get }
}
