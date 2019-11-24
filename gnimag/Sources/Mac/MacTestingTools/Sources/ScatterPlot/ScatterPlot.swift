//
//  Created by David Knothe on 07.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Cocoa
import Common
import Charts
import Image

public final class ScatterPlot {
    public let canvas: BitmapCanvas
    private let view: ScatterChartView

    /// Create a scatter plot with the given HasScatterDataSet object.
    /// The scatter plot is black and is drawn on a white background.
    /// Must be called on the UI thread.
    public convenience init(from object: HasScatterDataSet, scatterCircleSize: CGFloat = 3, outputImageSize: CGSize = CGSize(width: 600, height: 400)) {
        self.init(dataPoints: object.dataSet, scatterCircleSize: scatterCircleSize, outputImageSize: outputImageSize)
    }

    /// Create a scatter plot with the given data set.
    /// The scatter plot is black/red (using the given colors) and is drawn on a white background.
    /// Must be called on the UI thread.
    public init(dataPoints: [ScatterDataPoint], scatterCircleSize: CGFloat = 3, outputImageSize: CGSize = CGSize(width: 600, height: 400)) {
        let dataPoints = dataPoints.sorted { $0.x < $1.x }

        // Map sorted values to ChartDataEntries
        let entries = dataPoints.map { ChartDataEntry(x: $0.x, y: $0.y) }

        // Create DataSet and view
        let dataSet = ScatterChartDataSet(entries: entries)
        dataSet.setScatterShape(.circle)
        dataSet.scatterShapeSize = scatterCircleSize
        dataSet.drawValuesEnabled = false
        dataSet.colors = dataPoints.map { $0.color.NSColor }
        let data = ScatterChartData(dataSet: dataSet)

        view = ScatterChartView(frame: CGRect(origin: .zero, size: outputImageSize))
        view.data = data
        view.legend.enabled = false

        // Create BitmapCanvas from the scatter view
        canvas = BitmapCanvas(view: view)
    }

    /// Write the scatter plot to a given destination.
    public func write(to file: String) {
        canvas.write(to: file)
    }

    /// Write the scatter plot to the users desktop.
    public func writeToDesktop(name: String) {
        canvas.writeToDesktop(name: name)
    }

    // MARK: ScatterStrokable

    /// Draw the outline of the ScatterStrokable.
    public func stroke(_ scatterStrokable: ScatterStrokable, with color: Color, alpha: Double = 1, strokeWidth: Double = 1) {
        let strokable = scatterStrokable.concreteStrokable(for: self)
        let color = scatterStrokable.color.NSColor.imageColor
        canvas.stroke(strokable, with: color, alpha: alpha, strokeWidth: strokeWidth)
    }

    /// Convert a point in the dataset-space into its actual pixel location on the image.
    public func pixelPosition(of dataPoint: (x: Double, y: Double)) -> CGPoint {
        var rect = view.viewPortHandler.contentRect
        rect.origin.y = view.viewPortHandler.offsetBottom // Rect is ULO, we want LLO

        /// Convert a value from one range to another range, keeping its relative position.
        func convert(_ value: Double, from: SimpleRange<Double>, to: SimpleRange<Double>) -> Double {
            if from.lower == from.upper { return value }
            let pos = (value - from.lower) / (from.upper - from.lower)
            return to.lower + pos * (to.upper - to.lower)
        }

        // Convert x and y values
        let xFrom = SimpleRange(from: view.xAxis.axisMinimum, to: view.xAxis.axisMaximum)
        let xTo = SimpleRange(from: Double(rect.minX), to: Double(rect.maxX))
        let x = convert(dataPoint.x, from: xFrom, to: xTo)

        // Convert x and y values
        let yFrom = SimpleRange(from: view.leftAxis.axisMinimum, to: view.leftAxis.axisMaximum)
        let yTo = SimpleRange(from: Double(rect.minY), to: Double(rect.maxY))
        let y = convert(dataPoint.y, from: yFrom, to: yTo)

        return CGPoint(x: x, y: y)
    }
}
