//
//  Created by David Knothe on 22.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Input

/// ImageAnalyzer provides a method for analyzing an image.
/// ImageAnalyzer does not store any internal state; everything is passed via method parameters.
///
enum ImageAnalyzer {

    /// Analyze the image. Use the hints to accomplish more performant or better analysis.
    func analyze(image: Image, hints: AnalysisHints) -> Result<AnalysisResult, AnalysisError> {
        fatalError("Not yet implemented")
    }
}
