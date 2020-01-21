//
//  Created by David Knothe on 31.12.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// Properties of the playfield.
struct PlayfieldProperties {
    /// The lower and upper radii limiting the playfield.
    let lowerRadius: Double
    let upperRadius: Double

    /// The offset to the intrinsic bar coordinate system in which the bar's yCenter is defined.
    let offsetToBarCoordinateSystem: Double

    // MARK: Conversion

    /// Convert a playfield into PlayfieldProperties.
    static func from(playfield: Playfield, with player: PlayerCourse) -> PlayfieldProperties? {
        guard let size = player.size.average else { return nil }

        return PlayfieldProperties(
            lowerRadius: playfield.innerRadius + size / 2,
            upperRadius: playfield.fullRadius - size / 2,
            offsetToBarCoordinateSystem: playfield.innerRadius
        )
    }
}
