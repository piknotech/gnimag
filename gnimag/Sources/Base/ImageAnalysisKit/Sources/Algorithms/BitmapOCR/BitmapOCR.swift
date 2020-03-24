//
//  Created by David Knothe on 21.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import Image

/// BitmapOCR performs character recognition by comparing images to a concrete dataset and returning the character from the set which fitted the image most.
/// Use BitmapOCRCreator to create such a dataset.
/// Attention: BitmapOCR can only read single lines of text at once.
public final class BitmapOCR {
    /// The location of the dataset directory.
    let location: String

    /// Default initializer.
    public init(location: String) {
        self.location = location
    }
}
