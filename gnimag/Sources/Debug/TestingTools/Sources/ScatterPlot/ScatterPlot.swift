//
//  Created by David Knothe on 07.08.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
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
    public convenience init(from object: HasScatterDataSet, scatterCircleSize: CGFloat = 3, outputImageSize: CGSize? = nil) {
        self.init(dataPoints: object.dataSet, scatterCircleSize: scatterCircleSize, outputImageSize: outputImageSize)
    }

    /// Create a scatter plot with the given data set.
    /// The scatter plot is black/red (using the given colors) and is drawn on a transparent background.
    public init(
        dataPoints: [ScatterDataPoint],
        scatterCircleSize: CGFloat = 3,
        outputImageSize: CGSize? = nil,
        xRange: SimpleRange<Double>? = nil,
        yRange: SimpleRange<Double>? = nil,
        rangeAugmentation: Double = 5%
    ) {
        let dataPoints = dataPoints.sorted { $0.x < $1.x }

        // Map sorted values to ChartDataEntries
        let entries = dataPoints.map { ChartDataEntry(x: $0.x, y: $0.y) }

        // Create DataSet and view
        let dataSet = ScatterChartDataSet(entries: entries)
        dataSet.setScatterShape(.circle)
        dataSet.scatterShapeSize = scatterCircleSize
        dataSet.drawValuesEnabled = false
        dataSet.colors = dataPoints.map(\.color.concreteColor.NSColor)
        let data = ScatterChartData(dataSet: dataSet)

        // Calculate view size depending on dataset size
        let size = outputImageSize ?? {
            let pixelPerPoint: CGFloat = 2
            return CGSize(
                width: 300 + CGFloat(dataPoints.count) * pixelPerPoint,
                height: 200 + CGFloat(dataPoints.count) * pixelPerPoint / 2
            )
        }()

        view = ScatterChartView(frame: CGRect(origin: .zero, size: size))
        view.canDrawConcurrently = true
        if !dataSet.isEmpty { view.data = data }
        view.legend.enabled = false

        // Specify exact window (the default margin is too large)

        if let xMin = xRange?.lower ?? dataPoints.first?.x,
            let xMax = xRange?.upper ?? dataPoints.last?.x, xMax > xMin {
            let dist = xMax - xMin
            view.xAxis.axisMinimum = xMin - dist * rangeAugmentation
            view.xAxis.axisMaximum = xMax + dist * rangeAugmentation
        }

        if let yMin = yRange?.lower ?? (dataPoints.min { $0.y < $1.y })?.y,
            let yMax = yRange?.upper ?? (dataPoints.max { $0.y < $1.y })?.y, yMax > yMin {
            let dist = yMax - yMin
            view.leftAxis.axisMinimum = yMin - dist * rangeAugmentation
            view.leftAxis.axisMaximum = yMax + dist * rangeAugmentation
            view.rightAxis.axisMinimum = yMin - dist * rangeAugmentation
            view.rightAxis.axisMaximum = yMax + dist * rangeAugmentation
        }

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
    public func stroke(_ scatterStrokable: ScatterStrokable, with color: ScatterColor, alpha: Double = 1, strokeWidth: Double = 1, dash: Dash? = nil) {
        let color = color.concreteColor
        let strokable = scatterStrokable.concreteStrokable(for: self)
        canvas.stroke(strokable, with: color, alpha: alpha, strokeWidth: strokeWidth, dash: dash)
    }

    /// The x range of `dataContentRect`.
    public var dataContentXRange: SimpleRange<Double> {
        SimpleRange(from: Double(dataContentRect.minX), to: Double(dataContentRect.maxX))
    }

    /// The drawing area of the plot, in data point space.
    public var dataContentRect: CGRect {
         // Avoid returning an empty or invalid rect
        if view.data!.entryCount == 0 {
            return CGRect(x: -1, y: -1, width: 2, height: 2)
        } else {
            return CGRect(x: view.xAxis.axisMinimum, y: view.leftAxis.axisMinimum, width: view.xAxis.axisRange, height: view.leftAxis.axisRange)
        }
    }

    /// The drawing area of the plot, in pixel space.
    public var pixelContentRect: CGRect {
        var rect = view.viewPortHandler.contentRect
        rect.origin.y = view.viewPortHandler.offsetBottom // Rect is ULO, we want LLO
        return rect
    }

    /// Convert a point in the dataset-space into its actual pixel location on the image (i.e. pixel-space).
    public func pixelPosition(of dataPoint: (x: Double, y: Double)) -> CGPoint {
        let pixelRect = pixelContentRect, dataRect = dataContentRect

        /// Convert a value from one range to another range, keeping its relative position.
        func convert<T: FloatingPoint>(_ value: T, from: SimpleRange<T>, to: SimpleRange<T>) -> T {
            if from.isSinglePoint { return value }
            let pos = (value - from.lower) / from.size
            return to.lower + pos * to.size
        }

        // Convert x and y values
        let xFrom = SimpleRange(from: dataRect.minX, to: dataRect.maxX)
        let xTo = SimpleRange(from: pixelRect.minX, to: pixelRect.maxX)
        let x = convert(CGFloat(dataPoint.x), from: xFrom, to: xTo)

        // Convert x and y values
        let yFrom = SimpleRange(from: dataRect.minY, to: dataRect.maxY)
        let yTo = SimpleRange(from: pixelRect.minY, to: pixelRect.maxY)
        let y = convert(CGFloat(dataPoint.y), from: yFrom, to: yTo)

        return CGPoint(x: x, y: y)
    }
}
