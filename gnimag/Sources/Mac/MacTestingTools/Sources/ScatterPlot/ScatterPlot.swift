//
//  Created by David Knothe on 07.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Cocoa
import Charts

public enum ScatterPlot {
    /// Create a scatter plot with the given Has2DDataSet object and save it to a file.
    /// The scatter plot is black and is drawn on a white background.
    public static func create(from object: Has2DDataSet, scatterCircleSize: CGFloat, outputImageSize: CGSize, saveTo file: String) {
        let (xValues, yValues) = object.yieldDataSet()
        create(withXValues: xValues, yValues: yValues, scatterCircleSize: scatterCircleSize, outputImageSize: outputImageSize, saveTo: file)
    }

    /// Create a scatter plot with the given Has2DDataSet object and save it to the desktop.
    /// The scatter plot is black and is drawn on a white background.
    public static func create(from object: Has2DDataSet, scatterCircleSize: CGFloat, outputImageSize: CGSize, saveToDesktop name: String) {
        let desktop = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first!
        create(from: object, scatterCircleSize: scatterCircleSize, outputImageSize: outputImageSize, saveTo: desktop + "/" + name)
    }

    /// Create a scatter plot with the given data and save it to a file.
    /// The scatter plot is black and is drawn on a white background.
    public static func create(withXValues xValues: [Double], yValues: [Double], scatterCircleSize: CGFloat, outputImageSize: CGSize, saveToDesktop name: String) {
        let desktop = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first!
        create(withXValues: xValues, yValues: yValues, scatterCircleSize: scatterCircleSize, outputImageSize: outputImageSize, saveTo: desktop + "/" + name)
    }

    /// Create a scatter plot with the given data and save it to a file.
    /// The scatter plot is black and is drawn on a white background.
    public static func create(withXValues xValues: [Double], yValues: [Double], scatterCircleSize: CGFloat, outputImageSize: CGSize, saveTo file: String) {
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
        NSData(data: viewData).write(toFile: file, atomically: true)
    }
}
