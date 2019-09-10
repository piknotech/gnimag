//
//  Created by David Knothe on 10.09.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import Image

public protocol Strokable {
    /// Stroke `self onto the context. Perform transforms as neccessary, but revert them after drawing.
    func stroke(onto context: CGContext)
}

public protocol Fillable {
    /// Fill `self` on the context. Perform transforms as neccessary, but revert them after drawing.
    func fill(on context: CGContext)
}

extension BitmapCanvas {
    /// Draw the outline of the Strokable.
    @discardableResult
    public func stroke(_ strokable: Strokable, with color: Color, alpha: Double = 1, strokeWidth: Double = 1) -> BitmapCanvas {
        context.setLineWidth(CGFloat(strokeWidth))
        context.setStrokeColor(color.CGColor(withAlpha: alpha))
        strokable.stroke(onto: context)
        return self
    }

    /// Fill the interior of the Fillable.
    @discardableResult
    public func fill(_ fillable: Fillable, with color: Color, alpha: Double = 1, strokeWidth: Double = 1) -> BitmapCanvas {
        context.setFillColor(color.CGColor(withAlpha: alpha))
        fillable.fill(on: context)
        return self
    }
}
