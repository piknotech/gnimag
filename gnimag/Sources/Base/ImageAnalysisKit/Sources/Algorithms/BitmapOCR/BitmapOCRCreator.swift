//
//  Created by David Knothe on 22.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation
import Image

/// Use BitmapOCRCreator to create or extend an existing OCR dataset.
public final class BitmapOCRCreator {
    /// The directory where detected character images will be written to.
    private let outputDirectory: String

    /// Default initializer.
    public init(outputDirectory: String) {
        self.outputDirectory = outputDirectory
    }
}
