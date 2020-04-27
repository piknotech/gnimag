//
//  Created by David Knothe on 06.11.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation
import GameKit
import Geometry
import Image
import ImageAnalysisKit
import LoggingKit

final class DebugFrame: DebugFrameProtocol {
    typealias ParameterType = DebugParameters

    var index: Int
    var time: Double?
    
    /// Default initializer.
    init(index: Int) {
        self.index = index
    }

    // MARK: Hints
    let hints = Hints()

    /// Properties of the image analysis hints calculation.
    class Hints {
        var hints: AnalysisHints?
    }

    // MARK: Image Analysis
    let imageAnalysis = ImageAnalysis()

    /// Properties of the Image Analysis step.
    class ImageAnalysis {
        var image: Image!

        var outcome: Outcome!
        enum Outcome {
            case success
            case error
            case crashed
            case samePlayerPosition
        }

        var playfield = _Playfield()
        var coloring = _Coloring()
        var player = _Player()
        var bars = _Bars()

        /// Properties of the playfield search.
        class _Playfield {
            var result: Playfield?
        }

        /// Properties of the coloring search.
        class _Coloring {
            var result: Coloring?
            var failure: Failure?

            struct Failure {
                let pixels: [Pixel]
                let clusters: [SimpleClustering.Cluster<Color>]
            }
        }

        /// Properties of the player search.
        class _Player {
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
        class _Bars {
            var locations = [_BarLocation]()
            var result: [Bar]?

            var current: _BarLocation { locations.last! }

            func nextBarLocation() {
                locations.append(.init())
            }
        }

        /// A call to "locateBar".
        class _BarLocation {
            var startPixel: Pixel?
            var innerOBB: OBB?
            var upPosition: Pixel?
            var outerOBB: OBB?
            var failure: Failure?
            var result: Bar?

            enum Failure {
                case innerEdge
                case outerEdge
                case anglesDifferent(angle1: CGFloat, angle2: CGFloat)
                case widthsDifferent(width1: CGFloat, width2: CGFloat)
            }
        }
    }

    // MARK: Game Model Collection
    let gameModelCollection = GameModelCollection()

    /// Properties of the Game Model Collection step.
    class GameModelCollection {
        var wasPerformed = false

        var player = _Player()
        var bars = _Bars()

        /// Properties of the player tracking.
        class _Player {
            var linearAngle: Double?
            var integrityCheckSuccessful = false

            var angle = SimpleTrackerDebugInfo<AngularWrapper<LinearTracker>>()
            var size = SimpleTrackerDebugInfo<ConstantTracker>()
            var height = CompositeTrackerDebugInfo<ParabolaTracker>()

            /// Do necessary preparations before logging.
            func prepareForLogging() {
                angle.fetchFunctionInfos()
                angle.fetchDataSet(maxDataPoints: 100)

                // Jump tracker: only fetch the most recent segments
                height.fetchDataSet(numSegments: 25)
                height.fetchFunctionInfos(type: .all, numSegments: 25)
            }
        }

        /// Bundles the properties of all bar trackings.
        class _Bars {
            var all = [_Bar]()
            var current: _Bar { all.last! }

            func nextBar() {
                all.append(.init())
            }
        }

        /// A single bar tracker.
        class _Bar {
            var state: BarTrackerState?
            var integrityCheckSuccessful = false

            var angle = SimpleTrackerDebugInfo<AngularWrapper<LinearTracker>>()
            var width = SimpleTrackerDebugInfo<ConstantTracker>()
            var holeSize = SimpleTrackerDebugInfo<ConstantTracker>()
            var yCenter = CompositeTrackerDebugInfo<LinearTracker>()

            /// Do necessary preparations before logging.
            func prepareForLogging() {
                yCenter.fetchFunctionInfos(type: .all, numSegments: 3)
                yCenter.fetchDataSet(numSegments: 3)
            }
        }
    }

    // MARK: Tap Prediction
    let tapPrediction = TapPrediction()

    /// Properties of the Tap Prediction step.
    class TapPrediction {
        var wasLocked: Bool?
        var isLocked: Bool?
        var delay: Double?
        var fellBackToIdleStrategy = false

        // Properties for FullFramePlot
        var realTimeDuringTapPrediction: Double?
        var playerHeight = CompositeTrackerDebugInfo<ParabolaTracker>()
        var playerAngleConverter: PlayerAngleConverter?
        var executedTaps: [PerformedTap]?
        var scheduledTaps: [ScheduledTap]?
        var frame: PredictionFrame?
        var interactionRecorder: InteractionRecorder?

        // More plots
        var delayValues = SimpleTrackerDebugInfo<ConstantTracker>()
        var jumpVelocityValues = SimpleTrackerDebugInfo<ConstantTracker>()
        var gravityValues = SimpleTrackerDebugInfo<ConstantTracker>()
        var mostRecentSolution: TapPredictor.MostRecentSolution?

        /// Do necessary preparations before logging.
        func prepareForLogging() {
            for simple in [delayValues, jumpVelocityValues, gravityValues] {
                simple.fetchDataSet(maxDataPoints: .max)
                simple.fetchFunctionInfos()
            }

            playerHeight.fetchDataSet(numSegments: 10)
            playerHeight.fetchFunctionInfos(type: .noGuesses, numSegments: 10)
        }
    }
}
