//
//  Created by David Knothe on 31.12.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common

/// Properties of the playfield.
struct PlayfieldProperties {
    /// The lower and upper radii limiting the playfield.
    let lowerRadius: Double
    let upperRadius: Double

    /// The vertical size of the playfield.
    var size: Double {
        upperRadius - lowerRadius
    }

    /// The vertical range limiting the playfield.
    var range: SimpleRange<Double> {
        SimpleRange(from: lowerRadius, to: upperRadius)
    }

    /// The offset to the intrinsic bar coordinate system in which the bar's yCenter is defined.
    let offsetToBarCoordinateSystem: Double

    // MARK: Conversion

    /// Create PlayerProperties from the given playfield and player.
    init?(playfield: Playfield, with player: PlayerTracker) {
        guard let size = player.size.average else { return nil }

        lowerRadius = playfield.innerRadius + size / 2
        upperRadius = playfield.fullRadius - size / 2
        offsetToBarCoordinateSystem = playfield.innerRadius
    }
}
