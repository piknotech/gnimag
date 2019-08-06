//
//  Created by David Knothe on 06.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import ImageInput

public protocol ConvertibleToCGImage {
    /// Convert the instance to a CGImage.
    func toCGImage() -> CGImage
}
