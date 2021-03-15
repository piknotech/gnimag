//
//  Created by David Knothe on 10.03.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

struct AnalysisResult {
    /// The state of the prism, either idle or rotating.
    let prismState: PrismState

    /// All dots in the image.
    let dots: [Dot]
}

struct Dot {
    let color: DotColor
    let yCenter: Double
    let radius: Double
}

enum PrismState {
    case idle(top: DotColor)
    case rotating(towards: DotColor)
}
