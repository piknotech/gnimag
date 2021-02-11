//
//  Created by David Knothe on 10.04.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Foundation

/// ScreenInteractor bundles image-providing and tapping functionality for a specific (window-independent) screen region.
/// You can use the macOS screenshot tool (cmd+shift+4) to find the exact frame of a screen region you are interested in.
final class ScreenInteractor {
    /// The absolute location of the full interaction region on the screen, in ULO coordinates.
    private let frame: CGRect

    /// Default initializer.
    /// The frame is specified in absolute ULO coordinates.
    init(frame: CGRect) {
        self.frame = frame
    }

    /// An image provider providing the content of the specified rectangle.
    lazy var imageProvider = DisplayLinkedImageProvider {
        CGWindowListCreateImage(self.frame, .optionOnScreenOnly, kCGNullWindowID, [])!
    }

    /// A tapper tapping on the window.
    lazy var tapper = MouseTapper { self.frame }

    /// A dragger moving the mouse on the window.
    lazy var dragger = MouseDragger { self.frame }
}
