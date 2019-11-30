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
        context.strokeEllipse(in: boundingBox.rect)
    }

    public func fill(on context: CGContext) {
        let smaller = boundingBox.rect.insetBy(dx: -0.5, dy: -0.5)
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

extension LineSegment: Strokable {
    public func stroke(onto context: CGContext) {
        if isTrivial { return }
        context.move(to: startPoint)
        context.addLine(to: endPoint)
        context.strokePath()
    }
}

extension Ray: Strokable {
    public func stroke(onto context: CGContext) {
        if isTrivial { return }
        let tValues = [0] + tValuesForIntersection(with: context)
        strokeIfPossible(validTValues: tValues, context: context)
    }
}

extension Line: Strokable {
    public func stroke(onto context: CGContext) {
        if isTrivial { return }
        let tValues = tValuesForIntersection(with: context)
        strokeIfPossible(validTValues: tValues, context: context)
    }
}

fileprivate extension LineType {
    /// Get all t-values where `startPoint + t * normalizedDirection` intersects with one of the bounds of the context.
    func tValuesForIntersection(with context: CGContext) -> [CGFloat] {
        let lineWidth: CGFloat = 50 // The maximum line width any reasonable user would use. Any large value would work here.

        // Four corners of the context, inset by -maxLineWidth
        let ll = CGPoint(x: -lineWidth, y: -lineWidth)
        let lr = CGPoint(x: CGFloat(context.width) + lineWidth, y: -lineWidth)
        let ul = CGPoint(x: -lineWidth, y: CGFloat(context.height) + lineWidth)
        let ur = CGPoint(x: CGFloat(context.width) + lineWidth, y: CGFloat(context.height) + lineWidth)

        // Get intersection parameters for the four edges
        let polygon = Polygon(points: [ll, lr, ur, ul])
        return polygon.lineSegments.compactMap(tForIntersection(with:))
    }

    /// Stroke the points defined by `validTValues` if there are 2 or more elements.
    func strokeIfPossible(validTValues: [CGFloat], context: CGContext) {
        if validTValues.count >= 2 {
            let min = validTValues.min()!, max = validTValues.max()!
            let start = startPoint + min * normalizedDirection
            let end = startPoint + max * normalizedDirection
            context.move(to: start)
            context.addLine(to: end)
            context.strokePath()
        }
    }
}
