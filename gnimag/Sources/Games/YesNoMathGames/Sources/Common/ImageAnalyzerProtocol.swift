//
//  Created by David Knothe on 08.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Image

/// Common functionalities that ImageAnalyzers for yes/no math games possess.
protocol ImageAnalyzerProtocol {
    /// Initialize the ImageAnalyzer by detecting the ScreenLayout using the first image.
    /// Returns nil if the screen layout couldn't be detected.
    func initializeWithFirstImage(_ image: Image) -> ScreenLayout?

    /// States whether the ImageAnalyzer was already successfully initialized.
    var isInitialized: Bool { get }

    /// Analyze an image and return the exercise.
    /// Returns nil if no terms were found in the image.
    func analyze(image: Image) -> Exercise?
}
