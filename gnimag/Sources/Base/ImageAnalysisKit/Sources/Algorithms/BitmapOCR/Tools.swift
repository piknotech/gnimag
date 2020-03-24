//
//  Created by David Knothe on 24.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import Image

internal enum ComponentCombinationStrategy {
    static let none: (OCRComponent, OCRComponent) -> Bool = { a, b in false }

    /// Combine when the (x-values-specific) overlap range is large enough in relation to the width of the smaller component.
    /// `requiredOverlap` is in [0, 1] and defines how much relative overlap must be present.
    static func verticalOverlay(requiredOverlap: Double) -> (OCRComponent, OCRComponent) -> Bool {
        return { a, b in
            let smallerWidth = min(a.region.width, b.region.width)
            let overlap = a.region.xRange.intersection(with: b.region.xRange).size
            return overlap / Double(smallerWidth) >= requiredOverlap
        }
    }
}

internal extension Bounds {
    var xRange: SimpleRange<Double> {
        SimpleRange(from: Double(minX), to: Double(minX + width))
    }

    var yRange: SimpleRange<Double> {
        SimpleRange(from: Double(minY), to: Double(minY + height))
    }
}
