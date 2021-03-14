//
//  Created by David Knothe on 13.03.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Image

/// DotColor defines the three colors that the prism has and that every dot can have.
enum DotColor: Equatable, CaseIterable {
    case orange
    case violet
    case skyBlue

    /// Convert a Color into the nearest DotColor.
    /// If the color is not represented accurately by a DotColor, return nil.
    init?(color: Color) {
        if let value = (DotColor.allCases.first { $0.referenceColor.distance(to: color) < 0.15 }) {
            self = value
        } else {
            return nil
        }
    }

    /// A Color which approximately represents this DotColor.
    private var referenceColor: Color {
        switch self {
        case .orange: return Color(0.92, 0.35, 0.14)
        case .violet: return Color(0.51, 0.19, 0.58)
        case .skyBlue: return Color(0.27, 0.58, 0.81)
        }
    }

    // MARK: Prism Operations
    /// The color which comes after this color when rotating the prism counterclockwise.
    var next: DotColor {
        switch self {
        case .orange: return .violet
        case .violet: return .skyBlue
        case .skyBlue: return .orange
        }
    }

    /// The number of times the prism must be rotated counterclockwise to reach this color.
    /// Between 0 and 2.
    func distance(to other: DotColor) -> Int {
        if self == other { return 0 }
        if next == other { return 1 }
        return 2
    }
}
