//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

extension Collection {
    /// Count the number of objects where "predicate" is fulfilled.
    internal func count(where predicate: (Element) -> Bool) -> Int {
        filter(predicate).count
    }
}
