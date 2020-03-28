//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Image
import Tapping

/// Scrcpy provides input and output classes if you want to use the scrcpy application to communicate with an Android device.
enum Scrcpy {
    /// Create a new ImageProvider that returns the window content of the scrcpy application.
    /// scrcpy must be running and streaming.
    static var imageProvider: ImageProvider {
        let provider = AppWindowScreenProvider(appName: "scrcpy")
        provider.removeUpperWindowBorder = true
        return provider
    }

    /// Create a new Tapper that taps on the scrcpy application window.
    /// scrcpy must be running and streaming.
    static var tapper: Tapper & ArbitraryLocationTapper {
        WindowTapper(appName: "scrcpy")
    }
}
