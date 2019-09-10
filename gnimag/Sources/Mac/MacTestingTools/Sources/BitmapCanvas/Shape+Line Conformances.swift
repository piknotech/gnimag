//
//  Created by David Knothe on 10.09.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import Geometry
import Image

extension Circle: Strokable, Fillable {
    public func stroke(onto context: CGContext) {
        context.translateBy(x: 0.5, y: 0.5)
        context.strokeEllipse(in: enclosingRect)
        context.translateBy(x: -0.5, y: -0.5)
    }

    public func fill(on context: CGContext) {
        context.translateBy(x: 0.5, y: 0.5)
        context.fillEllipse(in: enclosingRect)
        context.translateBy(x: -0.5, y: -0.5)
    }
}

extension AABB: Strokable, Fillable {
    public func stroke(onto context: CGContext) {
        context.stroke(rect.insetBy(dx: 0.5, dy: 0.5))
    }

    public func fill(on context: CGContext) {
        context.fill(rect)
    }
}

extension OBB: Strokable, Fillable {
    private func rotate(context: CGContext, around point: CGPoint, angle: CGFloat) {
        context.translateBy(x: -point.x, y: -point.y)
        context.rotate(by: angle)
        context.translateBy(x: point.x, y: point.y)
    }

    public func stroke(onto context: CGContext) {
        rotate(context: context, around: center, angle: rotation)
        context.stroke(aabb.rect.insetBy(dx: 0.5, dy: 0.5))
        rotate(context: context, around: center, angle: -rotation)
    }

    public func fill(on context: CGContext) {
        rotate(context: context, around: center, angle: rotation)
        context.fill(aabb.rect)
        rotate(context: context, around: center, angle: -rotation)
    }
}

extension Geometry.Polygon: Strokable, Fillable {
    private func createPath(on context: CGContext) {
        context.beginPath()
        context.addLines(between: points) // TESTEN MIT 0/1 objekten
        context.closePath()
    }

    public func stroke(onto context: CGContext) {
        context.translateBy(x: 0.5, y: 0.5)
        createPath(on: context)
        context.strokePath()
        context.translateBy(x: -0.5, y: -0.5)
    }

    public func fill(on context: CGContext) {
        createPath(on: context)
        context.fillPath(using: .evenOdd)
    }
}
