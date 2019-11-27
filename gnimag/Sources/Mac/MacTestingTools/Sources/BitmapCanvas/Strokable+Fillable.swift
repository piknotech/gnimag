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
    private func setupStroke(color: Color, alpha: Double, strokeWidth: Double, dash: Dash?) {
        context.setLineCap(.round)
        context.setLineWidth(CGFloat(strokeWidth))
        context.setStrokeColor(color.CGColor(withAlpha: alpha))
        context.setLineDash(phase: 0, lengths: dash?.lengths ?? [])
    }

    /// Draw the outline of the Strokable.
    @discardableResult
    public func stroke(_ strokable: Strokable, with color: Color, alpha: Double = 1, strokeWidth: Double = 1, dash: Dash? = nil) -> BitmapCanvas {
        setupStroke(color: color, alpha: alpha, strokeWidth: strokeWidth, dash: dash)
        context.translateBy(x: 0.5, y: 0.5) // Pixel <-> CGPoint conversion
        strokable.stroke(onto: context)
        context.translateBy(x: -0.5, y: -0.5)
        return self
    }

    /// Fill the interior of the Fillable.
    @discardableResult
    public func fill(_ fillable: Fillable, with color: Color, alpha: Double = 1) -> BitmapCanvas {
        context.setFillColor(color.CGColor(withAlpha: alpha))
        setupStroke(color: color, alpha: alpha, strokeWidth: 1, dash: nil) // May be required for filling, e.g for CGPaths
        context.translateBy(x: 0.5, y: 0.5) // Pixel <-> CGPoint conversion
        fillable.fill(on: context)
        context.translateBy(x: -0.5, y: -0.5)
        return self
    }
}
