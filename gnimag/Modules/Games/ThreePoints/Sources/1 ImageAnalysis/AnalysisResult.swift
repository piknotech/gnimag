//
//  Created by David Knothe on 10.03.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common

struct AnalysisResult {
    /// The rotation of the prism; 0° means orange is on top.
    let prismRotation: Angle

    /// All dots in the image.
    let dots: [Dot]
}

struct Dot {
    let color: DotColor
    let yCenter: Double
    let radius: Double
}
