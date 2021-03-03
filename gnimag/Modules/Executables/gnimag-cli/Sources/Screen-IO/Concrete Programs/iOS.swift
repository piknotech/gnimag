//
//  Created by David Knothe on 04.01.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Image
import Tapping

/// AirServer provides an image provider for the AirServer application which you can use to mirror your iPhone.
let airServer = WindowInteractor(appName: "AirServer", windowNameHint: "iPhone").imageProvider

/// QuickTime provides an image provider for QuickTime Player which you can use to mirror your iPhone.
let quickTime = WindowInteractor(appName: "QuickTime Player").imageProvider
