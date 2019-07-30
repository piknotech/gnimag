//
//  Created by David Knothe on 30.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

public protocol DistanceMeasurable {
    /// Calculate the distance to another object of the same type.
    func distance(to other: Self) -> Double
}
