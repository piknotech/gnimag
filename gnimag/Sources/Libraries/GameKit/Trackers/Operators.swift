//
//  Created by David Knothe on 09.04.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

postfix operator %

/// Use % to write tolerance values, e.g. 5%.
postfix func %(a: Double) -> Double {
    return a * 0.01
}
