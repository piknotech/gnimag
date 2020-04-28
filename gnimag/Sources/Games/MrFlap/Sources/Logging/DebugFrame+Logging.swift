//
//  Created by David Knothe on 14.11.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import GameKit
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
        case .error, .crashed: return true
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

    /// States if the frame is interesting from a tap prediction perspective.
    /// This includes each frame where a lock was set.
    var interestingForTapPrediction: Bool {
        if tapPrediction.fellBackToIdleStrategy { return true }
        if let wasLocked = tapPrediction.wasLocked, let isLocked = tapPrediction.isLocked {
            return !wasLocked && isLocked
        }

        return false
    }

    /// States if the player was detected to have crashed.
    var playerCrashed: Bool {
        imageAnalysis.outcome == .some(.crashed)
    }

    /// Check if the frame should be logged given the severity.
    func isValidForLogging(with parameters: DebugParameters) -> Bool {
        if let num = parameters.controlFramerate, index.isMultiple(of: num) { return true }

        if parameters.occasions.contains(.imageAnalysisErrors) && hasImageAnalysisError { return true }
        if parameters.occasions.contains(.barLocationErrors) && hasBarLocationError { return true }
        if parameters.occasions.contains(.integrityErrors) && hasIntegrityError { return true }
        if parameters.occasions.contains(.interestingTapPrediction) && interestingForTapPrediction { return true }

        return false
    }

    /// Do preparations that are necessary before logging.
    /// This method is only called when "isValidForLogging" has returned `true`.
    /// These preparations are performed synchronously.
    func prepareSynchronously(with parameters: DebugParameters) {
        gameModelCollection.player.prepareForLogging()
        gameModelCollection.bars.all.forEach { $0.prepareForLogging() }
        tapPrediction.prepareForLogging()
    }

    // MARK: - Logging
    /// Create and return a subdirectory for logging this frame's content.
    func createSubdirectory(parameters: ParameterType) -> String? {
        // Create folder name, consisting of frame index and type
        let prefix = String(format: "%06d", index)
        var suffix: String

        switch (playerCrashed, hasIntegrityError, hasImageAnalysisError, hasBarLocationError, tapPrediction.fellBackToIdleStrategy) {
        case (true, _, _, _, _): suffix = "_Crashed"
        case (_, true, _, _, _): suffix = "_IntegrityError"
        case (_, _, true, _, _): suffix = "_AnalysisError"
        case (_, _, _, true, _): suffix = "_LocateBarError"
        case (_, _, _, _, true): suffix = "_FallbackToIdle"
        default: suffix = "_Okay"
        }

        let directory = parameters.location +/ (prefix + suffix)

        // Try creating directory
        do {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
            return directory
        } catch {
            Terminal.log(.error, "DebugLogger – subdirectory \"\(directory)\" couldn't be created!")
            return nil
        }
    }

    /// Log the frame to the given directory.
    /// This method is called asynchronously, i.e. an undefined time after the frame was actually live.
    func log(with parameters: DebugParameters) {
        guard let directory = createSubdirectory(parameters: parameters) else { return }

        // Log text
        if parameters.content.contains(.text) {
            let textPath = directory +/ "Frame.txt"
            try? fullLoggingText.write(toFile: textPath, atomically: false, encoding: .utf8)
        }

        // Log images
        if parameters.content.contains(.imageAnalysis) { logImageAnalysisImages(to: directory) }
        if parameters.content.contains(.gameModelCollection) { logGameModelCollectionImages(to: directory) }
        if parameters.content.contains(.tapPrediction) { logTapPredictionImages(to: directory) }
    }

    // MARK: Log Images

    /// Log all image analysis images.
    private func logImageAnalysisImages(to directory: String) {
        guard let image = imageAnalysis.image, let coloring = imageAnalysis.coloring.result else { return }

        // Add player to canvas
        let canvas = BitmapCanvas(image: image)!
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
            let canvas = BitmapCanvas(image: image)!
            _ = location.innerOBB.map { canvas.stroke($0, with: .white - coloring.secondary) }
            _ = location.outerOBB.map { canvas.stroke($0, with: .white - coloring.secondary) }
            _ = location.startPixel.map { canvas.fill($0, with: .white - coloring.theme, alpha: 0.5, width: 3) }
            _ = location.upPosition.map { canvas.fill($0, with: .white - coloring.theme, alpha: 1, width: 1) }
            canvas.write(to: directory +/ String(format: "locateBar_%02d.png", i + 1))
        }
    }

    /// Log scatter plots of relevant trackers from game model collection.
    private func logGameModelCollectionImages(to directory: String) {
        // Plot the yCenter of each bar
        for (i, bar) in gameModelCollection.bars.all.enumerated() {
            if let plot = bar.yCenter.createScatterPlot() {
                plot.write(to: directory +/ String(format: "bar_%02d_yCenter.png", i + 1))
            }
        }

        // Plot player height
        if let plot = gameModelCollection.player.height.createScatterPlot() {
            plot.write(to: directory +/ "player_height.png")
        }

        // Plot player angle
        if let plot = gameModelCollection.player.angle.createScatterPlot() {
            plot.write(to: directory +/ "player_angle.png")
        }
    }

    /// Log relevant scatter plots of tap prediction.
    /// This includes the FullFramePlot.
    private func logTapPredictionImages(to directory: String) {
        logFullFramePlot(to: directory)

        // Plot delay tracker
        if let plot = tapPrediction.delayValues.createScatterPlot(includeToleranceRegionForLastDataPoint: false) {
            plot.write(to: directory +/ "TapPredictionDelay.png")
        }

        // Plot jumpVelocity and gravity
        if let plot = tapPrediction.jumpVelocityValues.createScatterPlot(includeToleranceRegionForLastDataPoint: false) {
            plot.write(to: directory +/ "player_jumpVelocity.png")
        }

        if let plot = tapPrediction.gravityValues.createScatterPlot(includeToleranceRegionForLastDataPoint: false) {
            plot.write(to: directory +/ "player_gravity.png")
        }

        // Plot current solution
        if let mostRecent = tapPrediction.mostRecentSolution {
            let plot = SolutionPlot(frame: mostRecent.associatedPredictionFrame, solution: mostRecent.solution)
            plot.write(to: directory +/ "solution.png")
        }
    }

    /// Log the FullFramePlot if available.
    private func logFullFramePlot(to directory: String) {
        guard
            let time = time,
            let realTimeAfterProcessing = tapPrediction.realTimeDuringTapPrediction,
            let playerAngleConverter = tapPrediction.playerAngleConverter,
            let scheduledTaps = tapPrediction.scheduledTaps,
            let executedTaps = tapPrediction.executedTaps,
            let recorder = tapPrediction.interactionRecorder,
            let frame = tapPrediction.frame else { return }

        let data = FullFramePlotData(realFrameTime: time, realTimeAfterProcessing: realTimeAfterProcessing, playerHeight: tapPrediction.playerHeight, playerAngleConverter: playerAngleConverter, scheduledTaps: scheduledTaps, executedTaps: executedTaps, frame: frame, interactionRecorder: recorder)

        let plot = FullFramePlot(data: data)
        plot.write(to: directory +/ "FullFrame.png")
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
        let currentSolutionIsFromCurrentFrame = tapPrediction.mostRecentSolution?.referenceTime == tapPrediction.frame?.currentTime

        let barToString: (PlayerBarInteraction) -> String = { bar in
            "• timeUntilHittingCenter: \(bar.timeUntilHittingCenter); timeUntilLeaving: \(bar.timeUntilLeaving); holeMovementSections: \(bar.holeMovement.sections)"
        }

        return """
        ––––– TAP PREDICTION –––––
        (wasLocked: \(tapPrediction.wasLocked ??? "nil"), isLockedNow: \(tapPrediction.isLocked ??? "nil"))

        • Delay: \(tapPrediction.delay ??? "nil")
        • Time of PredictionFrame: \(tapPrediction.frame?.currentTime ??? "nil")

        Excerpt from PredictionFrame:
        • jumpVelocity (time-based): \(tapPrediction.frame?.jumping.jumpVelocity ??? "nil")
        • gravity (time-based): \(tapPrediction.frame?.jumping.gravity ??? "nil")

        Most recent solution:
        • referenceTime: \(tapPrediction.mostRecentSolution?.referenceTime ??? "nil") (is from current frame: \(currentSolutionIsFromCurrentFrame))
        • Solution: \(tapPrediction.mostRecentSolution?.solution ??? "nil")
        \(tapPrediction.fellBackToIdleStrategy ? "Fell back to idle strategy because singleBar didn't yield a solution!\n" : "")
        All interactions in most recent solution's frame:
        \(tapPrediction.mostRecentSolution?.associatedPredictionFrame.bars.map(barToString).joined(separator: "\n") ??? "nil")
        """
    }
}
