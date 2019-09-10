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
        context.strokeEllipse(in: enclosingRect)
    }

    public func fill(on context: CGContext) {
        let smaller = enclosingRect.insetBy(dx: -0.5, dy: -0.5)
        context.fillEllipse(in: smaller)
    }
}

extension AABB: Strokable, Fillable {
    public func stroke(onto context: CGContext) {
        context.stroke(rect)
    }

    public func fill(on context: CGContext) {
        let smaller = rect.insetBy(dx: -0.5, dy: -0.5)
        context.fill(smaller)
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
        context.stroke(aabb.rect)
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
        createPath(on: context)
        context.strokePath()
    }

    public func fill(on context: CGContext) {
        createPath(on: context)
        context.drawPath(using: .fillStroke) // Only calling "fillPath" will not draw the path's border
    }
}

// MARK: Lines
