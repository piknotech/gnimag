//
//  Created by David Knothe on 16.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Image
import GameKit
import Geometry
import TestingTools

/// FullFramePlot bundles plots from GameModelCollection and TapPrediction into one single, informative plot.
/// FullFramePlot is a time-height plot of the player.
/// To be precise, it shows actual detected time-height values of the player (i.e. the player's actual jumps) together with previously and future scheduled taps. This allows to compare previously scheduled taps to the actual resulting jumps.
/// In contrast to JumpSequencePlot, FullFramePlot shows the current real time (from timeProvider).
final class FullFramePlot {
    let plot: ScatterPlot

    /// Create a FullFramePlot from the given data.
    init(data: FullFramePlotData) {
        // Create ScatterPlot
        let yRange = SimpleRange(from: data.frame.playfield.lowerRadius, to: data.frame.playfield.upperRadius)
        plot = ScatterPlot(dataPoints: data.allDataPoints, yRange: yRange)

        // Draw playfield
        let lowerPlayfieldLine = HorizontalLineScatterStrokable(y: data.frame.playfield.lowerRadius)
        let upperPlayfieldLine = HorizontalLineScatterStrokable(y: data.frame.playfield.upperRadius)
        plot.stroke(lowerPlayfieldLine, with: .normal)
        plot.stroke(upperPlayfieldLine, with: .normal)

        // Draw all jumps
        for info in data.allFunctionInfos {
            plot.stroke(info.strokable, with: info.color, alpha: 0.75, strokeWidth: 0.5, dash: info.dash.concreteDash)
        }

        // Draw bars
        for bar in data.barScatterStrokables(in: plot.frame) {
            plot.stroke(bar, with: .normal, dash: Dash(on: 1, off: 1))
        }

        // Draw time markers
        let frameTime = VerticalLineScatterStrokable(x: data.realFrameTime)
        let predictionTime = VerticalLineScatterStrokable(x: data.frame.currentTime)
        plot.stroke(frameTime, with: .custom(.lightBlue), dash: Dash(on: 2, off: 2))
        plot.stroke(predictionTime, with: .custom(.lightBlue), dash: Dash(on: 2, off: 2))
    }

    /// Write the plot to a given destination.
    func write(to file: String) {
        plot.write(to: file)
    }

    /// Write the plot to the users desktop.
    func writeToDesktop(name: String) {
        plot.writeToDesktop(name: name)
    }
}

extension FullFramePlotData {
    private static var dataPointColor = Color.black
    private static var performedJumpColor = Color.white
    private static var scheduledJumpColor = Color.red

    /// The time of the earliest data point.
    private var earliestDataPointTime: Double {
        guard let firstAngle = playerHeight.allDataPoints?.first?.x else { return 0 }
        return playerAngleConverter.time(from: firstAngle)
    }

    /// Read the jumps which are stored in the given tap's debug infos.
    /// Discard jumps which start before a given absolute time.
    private func jumps(from taps: [ScheduledTap], startingAfter time: Double) -> [Jump] {
        taps.compactMap { tap in
            guard let info = tap.debugInfo else { return nil }
            let jump = info.jump.shiftedRight(by: info.referenceTime)
            if jump.startPoint.time < time { return nil }
            return jump
        }
    }

    /// All dataPoints (transformed to the correct time-space). These include:
    ///  - Existing time/height datapoints of the player.
    ///  - Expected start points of previously scheduled (i.e. already performed) jumps. Optimally, they would match the start points of the actual jumps.
    ///  – The scheduled jump points of the currently predicted tap sequence.
    var allDataPoints: [ScatterDataPoint] {
        var result = [ScatterDataPoint]()

        // Existing time/height datapoints of the player
        result += (playerHeight.allDataPoints ?? []).map { dataPoint -> ScatterDataPoint in
            let time = playerAngleConverter.time(from: dataPoint.x) // angle -> time conversion
            return ScatterDataPoint(x: time, y: dataPoint.y, color: .custom(Self.dataPointColor))
        }

        // Expected start points of performed jumps
        let executed = jumps(from: executedTaps.map(\.scheduledTap), startingAfter: earliestDataPointTime)
        result += executed.map {
            ScatterDataPoint(x: $0.startPoint.time, y: $0.startPoint.height, color: .custom(Self.performedJumpColor))
        }

        // Scheduled jumps of the currently predicted tap sequence
        let scheduled = jumps(from: scheduledTaps, startingAfter: earliestDataPointTime)
        result += scheduled.map {
            ScatterDataPoint(x: $0.startPoint.time, y: $0.startPoint.height, color: .custom(Self.scheduledJumpColor))
        }

        // Add final point
        if let last = (scheduled.last ?? executed.last)?.endPoint {
            let color = (scheduled.isEmpty) ? Self.performedJumpColor : Self.scheduledJumpColor
            result.append(ScatterDataPoint(x: last.time, y: last.height, color: .custom(color)))
        }

        return result
    }

    /// All functions (transformed to the correct time-space). These match the three types described by `allDataPoints`.`
    var allFunctionInfos: [FunctionDebugInfo] {
        var result = [FunctionDebugInfo]()

        // FIRST: Existing time/height datapoints of the player
        result += (playerHeight.allFunctions ?? []).map { function -> FunctionDebugInfo in
            let parabola = function.function as! Parabola
            let strokable = function.strokable as! QuadCurveScatterStrokable

            return FunctionDebugInfo(
                function: playerAngleConverter.timeBasedParabola(from: parabola),
                strokable: playerAngleConverter.timeBasedQuadCurveScatterStrokable(from: strokable),
                color: .custom(Self.dataPointColor),
                dash: .dashed
            )
        }

        // Expected start points of performed jumps and scheduled jumps of the currently predicted tap sequence
        let executedJumps = jumps(from: executedTaps.map(\.scheduledTap), startingAfter: earliestDataPointTime)
        let scheduledJumps = jumps(from: scheduledTaps, startingAfter: earliestDataPointTime)

        var allJumps = executedJumps + scheduledJumps
        if allJumps.isEmpty { return result }

        // Correct jump lengths so all jumps directly join each other (time-wise)
        for i in 0 ..< allJumps.count - 1 {
            let jump = allJumps[i], endTime = allJumps[i+1].startPoint.time
            let endPoint = Point(time: endTime, height: jump.parabola.at(endTime))
            allJumps[i] = Jump(startPoint: jump.startPoint, endPoint: endPoint, parabola: jump.parabola)
        }

        result += allJumps.enumerated().map { i, jump in
            let color = (i < executedJumps.count) ? Self.performedJumpColor : Self.scheduledJumpColor
            return FunctionDebugInfo(
                function: jump.parabola,
                strokable: QuadCurveScatterStrokable(parabola: jump.parabola, drawingRange: jump.timeRange),
                color: .custom(color),
                dash: .solid
            )
        }

        return result
    }

    /// The scatter strokables of all bars in the prediction frame (transformed to the correct time-space)
    /// Contains also all previous bars which are visible in the ScatterFrame.
    func barScatterStrokables(in scatterFrame: ScatterFrame) -> [ScatterStrokable] {
        let visiblePreviousBars = interactionRecorder.interactions(before: frame.currentTime, intersectingRange: scatterFrame.dataContentXRange)

        return (frame.bars + visiblePreviousBars).map { interaction in
            BarScatterStrokable(interaction: interaction).shiftedRight(by: CGFloat(interaction.currentTime))
        }
    }
}

// MARK: Transformations

private extension Jump {
    /// Shift a Jump to the right by the given amount.
    func shiftedRight(by amount: Double) -> Jump {
        let start = Point(time: startPoint.time + amount, height: startPoint.height)
        let end = Point(time: endPoint.time + amount, height: endPoint.height)
        let parabola = self.parabola.shiftedLeft(by: -amount)
        return Jump(startPoint: start, endPoint: end, parabola: parabola)
    }
}

private extension PlayerAngleConverter {
    /// Convert a QuadCurveScatterStrokable whose argument is angle into the same QuadCurveScatterStrokable whose argument is time.
    func timeBasedQuadCurveScatterStrokable(from scatterStrokable: QuadCurveScatterStrokable) -> QuadCurveScatterStrokable {
        let parabola = timeBasedParabola(from: scatterStrokable.parabola)
        let range = timeBasedRange(from: scatterStrokable.drawingRange).regularized
        return QuadCurveScatterStrokable(parabola: parabola, drawingRange: range)
    }
}

private extension ScatterStrokable {
    /// Return a ScatterStrokable drawing `self`, but shifted to the right.
    func shiftedRight(by amount: CGFloat) -> ScatterStrokable {
        HorizontallyShiftedScatterStrokable(wrapped: self, rightShift: amount)
    }
}

/// A ScatterStrokable shifting another ScatterStrokable in x-direction. The y-values stay unchanged.
private struct HorizontallyShiftedScatterStrokable: ScatterStrokable {
    let wrapped: ScatterStrokable
    let rightShift: CGFloat

    func concreteStrokable(for frame: ScatterFrame) -> Strokable {
        let shiftedDataContentRect = frame.dataContentRect.offsetBy(dx: -rightShift, dy: 0)
        let shiftedFrame = ScatterFrame(dataContentRect: shiftedDataContentRect, pixelContentRect: frame.pixelContentRect)
        return wrapped.concreteStrokable(for: shiftedFrame)
    }
}
