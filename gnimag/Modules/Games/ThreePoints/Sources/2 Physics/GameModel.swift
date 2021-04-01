//
//  Created by David Knothe on 15.03.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Foundation

/// The full, up-to-date model of the running game.
final class GameModel {
    var dots = [DotTracker]()
    var prism = PrismStateTracker()
}
