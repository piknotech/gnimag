//
//  Created by David Knothe on 06.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Cocoa
import Image

internal extension Color {
    /// Convert the Color to a CGColor with the given alpha component.
    func CGColor(withAlpha alpha: Double) -> CGColor {
        return NSColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha)).cgColor
    }
}

internal extension NSColor {
    /// Convert the NSColor to an Image.Color.
    var imageColor: Color {
        Color(Double(redComponent), Double(greenComponent), Double(blueComponent))
    }
}
