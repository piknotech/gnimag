//
//  Created by David Knothe on 22.08.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation
import Tapping

/// A Tapper which does nothing.
class NoopTapper: Tapper, ArbitraryLocationTapper {
    func tap() {
    }

    func tap(at point: CGPoint) {
    }
}
