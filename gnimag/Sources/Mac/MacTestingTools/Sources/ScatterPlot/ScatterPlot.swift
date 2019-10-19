//
//  Created by David Knothe on 07.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Cocoa
import Charts

public final class ScatterPlot {
    private let data: NSData

    /// Create a scatter plot with the given HasScatterDataSet object.
    /// The scatter plot is black and is drawn on a white background.
    public convenience init(from object: HasScatterDataSet, scatterCircleSize: CGFloat = 3, outputImageSize: CGSize = CGSize(width: 600, height: 400)) {
        self.init(dataPoints: object.dataSet, scatterCircleSize: scatterCircleSize, outputImageSize: outputImageSize)
    }

    /// Create a scatter plot with the given data set.
    /// The scatter plot is black/red (using the given colors) and is drawn on a white background.
    public init(dataPoints: [ScatterDataPoint], scatterCircleSize: CGFloat = 3, outputImageSize: CGSize = CGSize(width: 600, height: 400)) {
        let dataPoints = dataPoints.sorted { $0.x < $1.x }

        // Map sorted values to ChartDataEntries
        let entries = dataPoints.map { ChartDataEntry(x: $0.x, y: $0.y) }

        // Create DataSet and view
        let dataSet = ScatterChartDataSet(entries: entries, label: "DataSet")
        dataSet.setScatterShape(.circle)
        dataSet.scatterShapeSize = scatterCircleSize
        dataSet.drawValuesEnabled = false
        dataSet.colors = dataPoints.map { $0.color.color }
        let data = ScatterChartData(dataSet: dataSet)

        let view = ScatterChartView(frame: CGRect(origin: .zero, size: outputImageSize))
        view.data = data
        view.legend.enabled = false

        // Store image data
        let image = NSImage(size: view.bounds.size)
        image.lockFocusFlipped(true)
        NSColor.white.drawSwatch(in: view.bounds) // White background
        view.draw(view.bounds)
        image.unlockFocus()

        let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
        let viewData = rep.representation(using: .png, properties: [:])!
        self.data = NSData(data: viewData)
    }

    /// Write the scatter plot to a given destination.
    public func write(to file: String) {
        data.write(toFile: file, atomically: true)
    }

    /// Write the scatter plot to the users desktop.
    public func writeToDesktop(name: String) {
        let desktop = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first!
        write(to: desktop + "/" + name)
    }
}
