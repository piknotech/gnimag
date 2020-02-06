//
//  Created by David Knothe on 30.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// A jump sequence defined by the starting point of the first jump and the time distances for the following jump starts.
struct JumpSequenceFromSpecificPosition {
    /// The (time/height) starting point.
    let startingPoint: Point

    /// The time distances between all consecutive jumps.
    let jumpTimeDistances: [Double]

    /// The time from the last jump until the jump sequence has finished and fulfilled its purpose.
    let timeUntilEnd: Double

    /// Convert the jump time distances into actual Jumps.
    func jumps(with properties: JumpingProperties) -> [Jump] {
        Jump.jumps(forTimeDistances: jumpTimeDistances, timeUntilEnd: timeUntilEnd, startPoint: startingPoint, jumping: properties)
    }
}
