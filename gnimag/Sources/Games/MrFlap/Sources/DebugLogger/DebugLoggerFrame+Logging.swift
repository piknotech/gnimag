//
//  Created by David Knothe on 14.11.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import Image
import MacTestingTools

extension DebugLoggerFrame {
    // MARK: - HasError And IsValidForLogging
    var hasError: Bool {
        hasImageAnalysisError || hasIntegrityError
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

        // Check for coloring, player or bar failure
        if (imageAnalysis.coloring.failure != nil || imageAnalysis.player.failure != nil || imageAnalysis.bars.locations.any { $0.failure != nil }) {
            return true
        }

        return false
    }

    /// States if the frame contains an integrity error (from game model collection).
    var hasIntegrityError: Bool {
        return false
    }

    /// Check if the frame should be logged given the severity.
    func isValidForLogging(forSeverity severity: DebugParameters.Severity) -> Bool {
        switch severity {
        case .none: return false
        case .alwaysText: return true
        case .onErrors: return hasError
        }
    }

    // MARK: - Logging
    /// The filename, consisting of the frame index and of the error state.
    private var filenameForLogging: String {
        let prefix = String(format: "%06d", index)

        switch (hasImageAnalysisError, hasIntegrityError) {
        case (true, _): return "\(prefix)_AnalysisError"
        case (_, true): return "\(prefix)_IntegrityError"
        default: return "\(prefix)_Okay"
        }
    }

    /// Log the frame to the given directory.
    func log(to directory: String, severity: DebugParameters.Severity) {
        try? fullLoggingText.write(toFile: directory + "/" + filenameForLogging, atomically: false, encoding: .utf8)

        if hasError {
            logImageAnalysisImages(to: directory)
        }
    }

    /// Log all image analysis helper images.
    private func logImageAnalysisImages(to directory: String) {
        guard let image = imageAnalysis.image, let coloring = imageAnalysis.coloring.result else { return }

        // Create subdirectory for images
        let prefix = String(format: "%06d", index)
        let directory = directory + "/" + prefix + "/"
        do {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        } catch {
            Terminal.log(.warning, "DebugLogger – subdirectory \"\(directory)\" couldn't be created!")
            return
        }

        // Plain image
        let plainCanvas = BitmapCanvas(image: image)
        plainCanvas.write(to: directory + "image.png")

        // Player
        let playerCanvas = BitmapCanvas(image: image)
        if let searchCenter = imageAnalysis.player.searchCenter {
            playerCanvas.fill(searchCenter, with: coloring.safeLoggingColor, alpha: 0.5, width: 3)
        }
        if let eyePosition = imageAnalysis.player.eyePosition {
            playerCanvas.fill(eyePosition, with: coloring.safeLoggingColor, alpha: 1, width: 1)
        }
        if let obb = imageAnalysis.player.obb {
            playerCanvas.stroke(obb, with: .white - coloring.secondary) // Opposite color, white or black
        }
        playerCanvas.write(to: directory + "player.png")

        // All (successful) bars
        let barsCanvas = BitmapCanvas(image: image)
        for location in imageAnalysis.bars.locations where location.result != nil {
            guard let innerOBB = location.innerOBB, let outerOBB = location.outerOBB else { continue }
            barsCanvas.stroke(innerOBB, with: .white - coloring.secondary) // Opposite color, white or black
            barsCanvas.stroke(outerOBB, with: .white - coloring.secondary)
        }
        barsCanvas.write(to: directory + "allBars.png")

        // All unsuccessful "locateBar" calls
        for (i, location) in imageAnalysis.bars.locations.enumerated() where location.failure != nil {
            let canvas = BitmapCanvas(image: image)
            _ = location.innerOBB.map { canvas.stroke($0, with: .white - coloring.secondary) }
            _ = location.outerOBB.map { canvas.stroke($0, with: .white - coloring.secondary) }
            _ = location.startPixel.map { canvas.fill($0, with: .white - coloring.theme, alpha: 0.5, width: 3) }
            _ = location.upPosition.map { canvas.fill($0, with: .white - coloring.theme, alpha: 1, width: 1) }
            canvas.write(to: directory + String(format: "locateBar_%02d.png", i + 1))
        }
    }

    // MARK: Log Texts
    /// Create the full text that should be logged.
    private var fullLoggingText: String {
        let header = "FRAME \(index)"
        let texts = [header, logTextForHints, logTextForImageAnalysis, logTextForGameModelCollection, logTextForTapPrediction]
        return texts.joined(separator: "\n\n")
    }

    /// The log text describing the image analysis hints.
    private var logTextForHints: String {
        """
        ––––– IMAGE ANALYSIS HINTS –––––
        ...
        """
    }

    /// The log text describing image analysis.
    private var logTextForImageAnalysis: String {
        let coloringText = imageAnalysis.coloring.failure != nil ?
            "Coloring could not be found! Using last coloring: \(imageAnalysis.coloring.result ??? "nil")" :
            "Coloring: \(imageAnalysis.coloring.result ??? "nil")"

        let textForBarLocation: (Int, ImageAnalysis._BarLocation) -> String = { i, barLocation in
            """
            –– LocateBar-Call \(i + 1) ––
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

        • \(coloringText)
        • Playfield: \(imageAnalysis.playfield.result ??? "nil")

        ––– Player –––
        • Search center: \(imageAnalysis.player.searchCenter ??? "NOT FOUND")
        • Eye position: \(imageAnalysis.player.eyePosition ??? "NOT FOUND")
        • OBB: \(imageAnalysis.player.obb ??? "NOT FOUND")
        • Result: \(imageAnalysis.player.result ??? "NOT FOUND")

        ––– Bars –––
        1.: All \(imageAnalysis.bars.result?.count ?? 0) bars:
        \(barsResultText)

        2.: All calls to "locateBar":
        \(barLocationsText)
        """
    }

    /// The log text describing game model collection.
    private var logTextForGameModelCollection: String {
        """
        """
    }

    /// The log text describing tap prediction.
    private var logTextForTapPrediction: String {
        """
        """
    }
}
