//
//  Created by David Knothe on 06.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Cocoa
import Image

internal extension Color {
    /// Convert the Color to a CGColor with the given alpha component.
    func CGColor(withAlpha alpha: Double) -> CGColor {
        NSColor.withAlphaComponent(CGFloat(alpha)).cgColor
    }

    var NSColor: NSColor {
        Cocoa.NSColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1)
    }
}
