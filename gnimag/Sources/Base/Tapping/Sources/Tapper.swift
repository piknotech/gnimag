//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// A tapper can tap on a static, unspecified location on the phone screen.
/// Tappers are useful when a game just requires a single tap location to be played.

public protocol Tapper {
    /// Tap anywhere on the phone screen.
    /// Return immediately, even if the tap is executed asynchronously.
    func tap()
}