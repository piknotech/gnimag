//
//  Created by David Knothe on 06.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Cocoa
import ImageInput

extension Color {
    /// Convert the Color to an NSColor with the given alpha component.
    func NSColor(withAlpha alpha: Double) -> NSColor {
        return Cocoa.NSColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }
}
