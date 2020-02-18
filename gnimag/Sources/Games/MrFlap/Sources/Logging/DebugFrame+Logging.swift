//
//  Created by David Knothe on 14.11.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import Image
import LoggingKit
import TestingTools

extension DebugFrame {
    // MARK: - HasError And IsValidForLogging
    var hasError: Bool {
        hasImageAnalysisError || hasBarLocationError || hasIntegrityError
    }

    /// States if the frame contains an image analysis error.
    var hasImageAnalysisError: Bool {
        // Check image analysis outcome
        switch imageAnalysis.outcome {
        case .none: return false // Image analysis wasn't executed
        case .samePlayerPosition: return false // No game model collection etc. happened
        case .error: return true
        case .success: break
        }

        // Check for coloring or player failure
        return imageAnalysis.coloring.failure != nil || imageAnalysis.player.failure != nil
    }

    /// States if the frame contains an unsuccessful call to "locateBar".
    var hasBarLocationError: Bool {
        imageAnalysis.bars.locations.any { $0.failure != nil }
    }

    /// States if the frame contains an integrity error (from game model collection).
    var hasIntegrityError: Bool {
        gameModelCollection.wasPerformed &&
            (!gameModelCollection.player.integrityCheckSuccessful ||
            gameModelCollection.bars.all.any { !$0.integrityCheckSuccessful })
    }

    /// Check if the frame should be logged given the severity.
    func isValidForLogging(with parameters: DebugParameters) -> Bool {
        switch parameters.severity {
        case .none: return false
        case .alwaysText: return true
        case .onErrors, .onErrorsTextOnly: return hasError
        case .onIntegrityErrors: return hasIntegrityError
        }
    }

    /// Do preparations that are necessary before logging.
    /// This method is only called when "isValidForLogging" has returned `true`.
    /// These preparations are performed synchronously.
    func prepareSynchronously(with parameters: DebugParameters) {
        // Prepare tracker debug infos
        gameModelCollection.player.prepareForLogging()
        gameModelCollection.bars.all.forEach { $0.prepareForLogging() }
    }

    // MARK: - Logging
    /// Create and return a subdirectory for logging this frame's content.
    func createSubdirectory(parameters: ParameterType) -> String? {
        // Create folder name, consisting of frame index and type
        let prefix = String(format: "%06d", index)
        var suffix: String

        switch (hasIntegrityError, hasImageAnalysisError, hasBarLocationError) {
        case (true, _, _): suffix = "_IntegrityError"
        case (_, true, _): suffix = "_AnalysisError"
        case (_, _, true): suffix = "_LocateBarError"
        default: suffix = "_Okay"
        }

        let directory = parameters.location +/ (prefix + suffix)

        // Try creating directory
        do {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
            return directory
        } catch {
            Terminal.log(.warning, "DebugLogger – subdirectory \"\(directory)\" couldn't be created!")
            return nil
        }
    }

    /// Log the frame to the given directory.
    /// This method is called asynchronously, i.e. an undefined time after the frame was actually live.
    func log(with parameters: DebugParameters) {
        guard let directory = createSubdirectory(parameters: parameters) else { return }

        // Log text
        let textPath = directory +/ "Frame.txt"
        try? fullLoggingText.write(toFile: textPath, atomically: false, encoding: .utf8)

        // Log images
        if hasError && !parameters.severity.noImages {
            logImageAnalysisImages(to: directory)
            logRelevantScatterPlots(to: directory)
        }
    }

    // MARK: Log Images

    /// Log all image analysis images.
    private func logImageAnalysisImages(to directory: String) {
        guard let image = imageAnalysis.image, let coloring = imageAnalysis.coloring.result else { return }

        // Add player to canvas
        let canvas = BitmapCanvas(image: image)
        if let searchCenter = imageAnalysis.player.searchCenter {
            canvas.fill(searchCenter, with: coloring.safeLoggingColor, alpha: 0.5, width: 3)
        }
        if let eyePosition = imageAnalysis.player.eyePosition {
            canvas.fill(eyePosition, with: coloring.safeLoggingColor, alpha: 1, width: 1)
        }
        if let obb = imageAnalysis.player.obb {
            canvas.stroke(obb, with: .white - coloring.secondary) // Opposite color, white or black
        }

        // Add bars to canvas
        for location in imageAnalysis.bars.locations where location.result != nil {
            guard let innerOBB = location.innerOBB, let outerOBB = location.outerOBB else { continue }
            canvas.stroke(innerOBB, with: .white - coloring.secondary) // Opposite color, white or black
            canvas.stroke(outerOBB, with: .white - coloring.secondary)
        }
        canvas.write(to: directory +/ "playerAndBars.png")

        // All unsuccessful "locateBar" calls
        for (i, location) in imageAnalysis.bars.locations.enumerated() where location.failure != nil {
            let canvas = BitmapCanvas(image: image)
            _ = location.innerOBB.map { canvas.stroke($0, with: .white - coloring.secondary) }
            _ = location.outerOBB.map { canvas.stroke($0, with: .white - coloring.secondary) }
            _ = location.startPixel.map { canvas.fill($0, with: .white - coloring.theme, alpha: 0.5, width: 3) }
            _ = location.upPosition.map { canvas.fill($0, with: .white - coloring.theme, alpha: 1, width: 1) }
            canvas.write(to: directory +/ String(format: "locateBar_%02d.png", i + 1))
        }
    }

    /// Log scatter plots of relevant trackers.
    private func logRelevantScatterPlots(to directory: String) {
        // Plot the yCenter of each bar
        for (i, bar) in self.gameModelCollection.bars.all.enumerated() {
            if let plot = bar.yCenter.createScatterPlot() {
                plot.write(to: directory +/ String(format: "bar_%02d_yCenter.png", i + 1))
            }
        }

        // Plot the player height
        if let plot = self.gameModelCollection.player.height.createScatterPlot() {
            plot.write(to: directory +/ "player_height.png")
        }
    }

    // MARK: Log Texts
    /// Create the full text that should be logged.
    private var fullLoggingText: String {
        let header = "FRAME \(index)\n" + "time: \(time ??? "nil")"
        let texts = [header, logTextForHints, logTextForImageAnalysis, logTextForGameModelCollection, logTextForTapPrediction]
        return texts.joined(separator: "\n\n\n")
    }

    /// The log text describing the image analysis hints.
    private var logTextForHints: String {
        """
        ––––– IMAGE ANALYSIS HINTS –––––
        • Using Initial Hints: \(hints.usingInitialHints)
        • Hints: \(hints.hints ??? "nil")
        """
    }

    /// The log text describing image analysis.
    private var logTextForImageAnalysis: String {
        let coloringText = imageAnalysis.coloring.failure != nil ?
            "Coloring could not be found! Using last coloring: \(imageAnalysis.coloring.result ??? "nil")" :
            "Coloring: \(imageAnalysis.coloring.result ??? "nil")"

        let textForBarLocation: (Int, ImageAnalysis._BarLocation) -> String = { i, barLocation in
            """
            –– LocateBar-Call \(i + 1) –– (\(barLocation.failure == nil ? "okay" : "FAILURE"))
            • startPixel: \(barLocation.startPixel ??? "nil")
            • innerOBB: \(barLocation.innerOBB ??? "nil")
            • upPosition: \(barLocation.upPosition ??? "nil")
            • outerOBB: \(barLocation.outerOBB ??? "nil")
            • failure: \(barLocation.failure ??? "nil")
            • result: \(barLocation.result ??? "nil")
            """
        }

        let barsResultText = imageAnalysis.bars.result?.map(anyDescription(of:)).joined(separator: "\n") ??? "nil"
        let barLocationsText = imageAnalysis.bars.locations.enumerated().map(textForBarLocation).joined(separator: "\n\n")

        return """
        ––––– IMAGE ANALYSIS –––––
        (outcome: \(imageAnalysis.outcome ??? "nil"))

        • \(coloringText)
        • Playfield: \(imageAnalysis.playfield.result ??? "nil")

        ––– Player –––
        • Search center: \(imageAnalysis.player.searchCenter ??? "NOT FOUND")
        • Eye position: \(imageAnalysis.player.eyePosition ??? "NOT FOUND")
        • OBB: \(imageAnalysis.player.obb ??? "NOT FOUND")
        • Result: \(imageAnalysis.player.result ??? "NOT FOUND")
        • Failure: \(imageAnalysis.player.failure ??? "nil")

        ––– Bars –––
        1.: All \(imageAnalysis.bars.result?.count ?? 0) bars:
        \(barsResultText)

        2.: All calls to "locateBar":
        \(barLocationsText)
        """
    }

    /// The log text describing game model collection.
    private var logTextForGameModelCollection: String {
        let playerInteger = gameModelCollection.player.integrityCheckSuccessful

        let textForBar: (Int, GameModelCollection._Bar) -> String = { i, bar in
            """
            –– Bar \(i + 1) –– (\(bar.integrityCheckSuccessful ? "okay" : "FAILURE"))
            • integer: \(bar.integrityCheckSuccessful)
            • state: \(bar.state ??? "nil")
            • angle: \(bar.angle ??? "nil")
            • width: \(bar.width ??? "nil")
            • holeSize: \(bar.holeSize ??? "nil")
            • yCenter: \(bar.yCenter ??? "nil")
            """
        }

        let barsText = gameModelCollection.bars.all.enumerated().map(textForBar).joined(separator: "\n\n")

        return """
        ––––– GAME MODEL COLLECTION –––––
        (was performed: \(gameModelCollection.wasPerformed))

        ––– Player ––– (\(playerInteger ? "okay" : "FAILURE"))
        • Integer: \(playerInteger)
        • Linear Angle: \(gameModelCollection.player.linearAngle ??? "nil")
        • Angle: \(gameModelCollection.player.angle ??? "nil")
        • Size: \(gameModelCollection.player.size ??? "nil")
        • Height: \(gameModelCollection.player.height ??? "nil")

        ––– Bars –––
        \(barsText)
        """
    }

    /// The log text describing tap prediction.
    private var logTextForTapPrediction: String {
        """
        ––––– TAP PREDICTION –––––
        tbd
        """
    }
}