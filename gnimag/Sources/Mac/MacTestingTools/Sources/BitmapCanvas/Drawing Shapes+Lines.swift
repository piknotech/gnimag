//
//  Created by David Knothe on 10.09.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import Geometry
import Image

// MARK: Shapes

extension Circle: Strokable, Fillable {
    public func stroke(onto context: CGContext) {
        context.strokeEllipse(in: enclosingRect.offsetBy(dx: 0.5, dy: 0.5))
    }

    public func fill(on context: CGContext) {
        let extended = enclosingRect.insetBy(dx: -0.5, dy: -0.5).offsetBy(dx: 0.5, dy: 0.5)
        context.fillEllipse(in: extended)
    }
}

extension AABB: Strokable, Fillable {
    public func stroke(onto context: CGContext) {
        context.stroke(rect.offsetBy(dx: 0.5, dy: 0.5))
    }

    public func fill(on context: CGContext) {
        let extended = rect.insetBy(dx: -0.5, dy: -0.5).offsetBy(dx: 0.5, dy: 0.5)
        context.fill(extended)
    }
}

extension OBB: Strokable, Fillable {
    private func rotate(context: CGContext, around point: CGPoint, angle: CGFloat) {
        context.translateBy(x: point.x, y: point.y)
        context.rotate(by: angle)
        context.translateBy(x: -point.x, y: -point.y)
    }

    public func stroke(onto context: CGContext) {
        rotate(context: context, around: center, angle: rotation)
        aabb.stroke(onto: context)
        rotate(context: context, around: center, angle: -rotation)
    }

    public func fill(on context: CGContext) {
        rotate(context: context, around: center, angle: rotation)
        aabb.fill(on: context)
        rotate(context: context, around: center, angle: -rotation)
    }
}

extension Geometry.Polygon: Strokable, Fillable {
    private func createPath(on context: CGContext) {
        context.beginPath()
        context.addLines(between: points)
        context.closePath()
    }

    public func stroke(onto context: CGContext) {
        context.translateBy(x: 0.5, y: 0.5)
        createPath(on: context)
        context.strokePath()
        context.translateBy(x: -0.5, y: -0.5)
    }

    public func fill(on context: CGContext) {
        context.translateBy(x: 0.5, y: 0.5)
        createPath(on: context)
        context.drawPath(using: .fillStroke) // Only calling "fillPath" will not draw the path's border
        context.translateBy(x: -0.5, y: -0.5)
    }
}

// MARK: Lines
