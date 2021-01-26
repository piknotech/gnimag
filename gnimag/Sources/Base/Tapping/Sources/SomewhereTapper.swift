//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

/// A SomewhereTapper can tap somewhere on the target, i.e. on an unspecified location.
public protocol SomewhereTapper {
    /// Tap somewhere on the target.
    /// Return immediately, even if the tap is executed asynchronously.
    func tap()
}
