//
//  Created by David Knothe on 06.11.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import Geometry
import Image
import ImageAnalysisKit
import MacTestingTools

/// DebugLoggerFrame stores all relevant data of a single frame, consisting of image analysis, game model collection, and tap prediction.
final class DebugLoggerFrame {
    let index: Int

    /// Default initializer.
    init(index: Int) {
        self.index = index
    }

    // MARK: Image Analysis
    var imageAnalysis = ImageAnalysis()

    /// Properties of the Image Analysis step.
    class ImageAnalysis {
        var image: Image!

        var outcome: Outcome!
        enum Outcome {
            case success
            case error
            case samePlayerPosition
        }

        var playfield = _Playfield()
        var coloring = _Coloring()
        var player = _Player()
        var bars = _Bars()

        /// Properties of the playfield search.
        struct _Playfield {
            var result: Playfield?
        }

        /// Properties of the coloring search.
        struct _Coloring {
            var result: Coloring?
            var failure: Failure?

            struct Failure {
                let pixels: [Pixel]
                let chunks: [ConnectedChunks.Chunk<Color>]
            }
        }

        /// Properties of the player search.
        struct _Player {
            var searchCenter: Pixel?
            var eyePosition: Pixel?
            var obb: OBB?
            var failure: Failure?
            var result: Player?

            enum Failure {
                case eyeNotFound
                case edgeTooLarge
            }
        }

        /// Bundles the properties of all bar searches.
        struct _Bars {
            var locations = [_BarLocation]()
            var result: [Bar]?

            var current: _BarLocation { locations.last! }

            mutating func addNewLocation() {
                locations.append(.init())
            }
        }

        /// A call to "locateBar".
        class _BarLocation {
            var startPixel: Pixel?
            var innerOBB: OBB?
            var outerOBB: OBB?
            var upPosition: Pixel?
            var failure: Failure?
            var result: Bar?

            enum Failure {
                case innerEdge
                case outerEdge
                case anglesDifferent
                case widthsDifferent
            }
        }
    }

    // MARK: Game Model Collection
}

// MARK: Interesting For Severity

extension DebugLoggerFrame {
    /// States if the frame contains an error, either image-analysis- or integrity-wise.
    var hasError: Bool {
        // Check image analysis outcome
        switch imageAnalysis.outcome {
        case .none: return false // Image analysis wasn't executed
        case .samePlayerPosition: return false // No game model collection etc. happened
        case .error: return true
        case .success: break
        }

        // TODO: switch gameModelCollection.outcome etc.

        return false
    }

    /// Check if the frame should be logged given the severity.
    func isInteresting(forSeverity severity: DebugParameters.Severity) -> Bool {
        switch severity {
        case .none: return false
        case .alwaysText: return true
        case .onErrors: return hasError
        }
    }
}

// MARK: Logging

extension DebugLoggerFrame {
    private var filenameForLogging: String {
        let prefix = String(format: "%06d", index)

        switch imageAnalysis.outcome {
        case .success, .none, .samePlayerPosition: break
        case .error: return "\(prefix)_ImageAnalysisError"
        }

        // TODO: switch gameModelCollection.outcome etc.

        return "\(prefix)_Okay"
    }

    /// Log the frame to the given directory.
    func log(to directory: String, severity: DebugParameters.Severity) {
        try? fullLoggingText.write(toFile: directory + "/" + filenameForLogging, atomically: true, encoding: .utf8)

        if hasError {
            logImageAnalysisImages(to: directory)
        }
    }

    /// Create the full text for logging.
    private var fullLoggingText: String {
        """
        ––––– IMAGE ANALYSIS –––––

        ––– Player –––
        • Search center: \(imageAnalysis.player.searchCenter)
        """
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
        }

        // Plain image
        let plainCanvas = BitmapCanvas(image: image)
        plainCanvas.write(to: directory + "image.png")

        // Player
        let playerCanvas = BitmapCanvas(image: image)
        if let searchCenter = imageAnalysis.player.searchCenter {
            playerCanvas.fill(searchCenter, with: coloring.safeLoggingColor, alpha: 0.5, width: 3)
        }
        if let eyePosition = imageAnalysis.player.eyePosition { // TODO: ??
            playerCanvas.fill(eyePosition, with: coloring.safeLoggingColor, alpha: 1, width: 1)
        }
        if let obb = imageAnalysis.player.obb {
            playerCanvas.stroke(obb, with: Color.white - coloring.secondary) // Opposite color, white or black
        }
        playerCanvas.write(to: directory + "player.png")

        // ...
    }
}
