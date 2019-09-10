//
//  Created by David Knothe on 10.09.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import Geometry
import Image

extension BitmapCanvas {
    private func prepareStroke(color: Color, alpha: Double, strokeWidth: Double) {
        context.setLineWidth(CGFloat(strokeWidth))
        context.setStrokeColor(color.CGColor(withAlpha: alpha))
    }

    private func prepareFill(color: Color, alpha: Double) {
        context.setFillColor(color.CGColor(withAlpha: alpha))
    }

    /// Draw the outline of a circle.
    @discardableResult
    public func stroke(_ circle: Circle, with color: Color, alpha: Double = 1, strokeWidth: Double = 1) -> BitmapCanvas {
        let rect = CGRect(x: circle.center.x - circle.radius + 0.5, y: circle.center.y - circle.radius + 0.5, width: 2 * circle.radius, height: 2 * circle.radius)
        prepareStroke(color: color, alpha: alpha, strokeWidth: strokeWidth)
        context.strokeEllipse(in: rect)
        return self
    }

    /// Fill a circle.
    @discardableResult
    public func fill(_ circle: Circle, with color: Color, alpha: Double = 1, strokeWidth: Double = 1) -> BitmapCanvas {
        let rect = CGRect(x: circle.center.x - circle.radius + 0.5, y: circle.center.y - circle.radius + 0.5, width: 2 * circle.radius, height: 2 * circle.radius)
        prepareFill(color: color, alpha: alpha)
        context.fillEllipse(in: rect)
        return self
    }

    /// Draw the outline of an AABB.
    @discardableResult
    public func stroke(_ aabb: AABB, with color: Color, alpha: Double = 1, strokeWidth: Double = 1) -> BitmapCanvas {
        let size = CGSize(width: aabb.width + 1, height: aabb.height + 1)
        let rect = CGRect(origin: aabb.rect.origin, size: size)
        prepareStroke(color: color, alpha: alpha, strokeWidth: strokeWidth)
        context.stroke(rect)
        return self
    }

    /// Fill an AABB.
    @discardableResult
    public func fill(_ aabb: AABB, with color: Color, alpha: Double = 1, strokeWidth: Double = 1) -> BitmapCanvas {
        let size = CGSize(width: aabb.width + 1, height: aabb.height + 1)
        let rect = CGRect(origin: aabb.rect.origin, size: size)
        prepareStroke(color: color, alpha: alpha, strokeWidth: strokeWidth)
        context.stroke(rect)
        return self
    }

    /// Draw the outline of an OBB.
    @discardableResult
    public func stroke(_ obb: OBB, with color: Color, alpha: Double = 1, strokeWidth: Double = 1) -> BitmapCanvas {
        context.rotate(by: -obb.rotation)
        stroke(obb.aabb, with: color, alpha: alpha, strokeWidth: strokeWidth)
        context.rotate(by: obb.rotation)
        return self
    }

    /// Fill an OBB.
    @discardableResult
    public func fill(_ obb: OBB, with color: Color, alpha: Double = 1, strokeWidth: Double = 1) -> BitmapCanvas {
        context.rotate(by: -obb.rotation)
        fill(obb.aabb, with: color, alpha: alpha)
        context.rotate(by: obb.rotation)
        return self
    }

    /// Draw the outline of a polygon.
    @discardableResult
    public func stroke(_ polygon: Geometry.Polygon, with color: Color, alpha: Double = 1, strokeWidth: Double = 1) -> BitmapCanvas {
        createPath(for: polygon)
        prepareStroke(color: color, alpha: alpha, strokeWidth: strokeWidth)
        context.strokePath()
        return self
    }

    /// Fill a polygon.
    @discardableResult
    public func fill(_ polygon: Geometry.Polygon, with color: Color, alpha: Double = 1, strokeWidth: Double = 1) -> BitmapCanvas {
        createPath(for: polygon)
        prepareFill(color: color, alpha: alpha)
        context.fillPath(using: .evenOdd)
        return self
    }

    /// Add the path of the polygon to the context.
    private func createPath(for polygon: Geometry.Polygon) {
        context.beginPath()
        context.addLines(between: polygon.points) // TESTEN MIT 0/1!
        context.closePath()
    }
}
