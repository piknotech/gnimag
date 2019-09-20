//
//  Created by David Knothe on 07.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Cocoa
import Charts

public class ScatterPlot {
    private let data: NSData

    /// Create a scatter plot with the given Has2DDataSet object.
    /// The scatter plot is black and is drawn on a white background.
    public convenience init(from object: Has2DDataSet, scatterCircleSize: CGFloat = 3, outputImageSize: CGSize = CGSize(width: 600, height: 400)) {
        let (xValues, yValues) = object.yieldDataSet()
        self.init(xValues: xValues, yValues: yValues, scatterCircleSize: scatterCircleSize, outputImageSize: outputImageSize)
    }

    /// Create a scatter plot with the given data.
    /// The scatter plot is black and is drawn on a white background.
    public init(xValues: [Double], yValues: [Double], scatterCircleSize: CGFloat = 3, outputImageSize: CGSize = CGSize(width: 600, height: 400)) {
        // Map values to ChartDataEntries
        let entries = zip(xValues, yValues).map { x, y in
            ChartDataEntry(x: x, y: y)
        }

        // Create DataSet and view
        let dataSet = ScatterChartDataSet(entries: entries, label: "DataSet")
        dataSet.setScatterShape(.circle)
        dataSet.colors = [.black]
        dataSet.scatterShapeSize = scatterCircleSize
        let data = ScatterChartData(dataSet: dataSet)

        let view = ScatterChartView(frame: CGRect(origin: .zero, size: outputImageSize))
        view.data = data

        // Save view to file
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
