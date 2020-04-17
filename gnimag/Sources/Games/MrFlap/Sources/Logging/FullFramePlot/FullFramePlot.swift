//
//  Created by David Knothe on 16.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import GameKit
import TestingTools

/// FullFramePlot bundles plots from GameModelCollection and TapPrediction into one single, informative plot.
/// FullFramePlot is a time-height plot of the player.
/// To be precise, it shows actual detected time-height values of the player (i.e. the player's actual jumps) together with previously and future scheduled taps. This allows to compare previously scheduled taps to the actual resulting jumps.
/// In contrast to JumpSequencePlot, FullFramePlot shows the current real time (from timeProvider).
final class FullFramePlot {
    let plot: ScatterPlot

    /// Create a FullFramePlot from the given data.
    init(data: FullFramePlotData) {
        plot = ScatterPlot(dataPoints: data.allDataPoints)

        for info in data.allFunctionInfos {
            plot.stroke(info.strokable, with: info.color, alpha: 0.75, strokeWidth: 0.5, dash: info.dash.concreteDash)
        }

        for bar in data.barScatterStrokables {
            plot.stroke(bar, with: .normal, dash: Dash(on: 1, off: 1))
        }
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
    /// All dataPoints (transformed to the correct time-space). These include:
    ///  - Existing time/height datapoints of the player.
    ///  - Expected start points of previously scheduled jumps. Optimally, they match the start points of the actual jumps.
    ///  – The scheduled jump points of the currently predicted tap sequence.
    var allDataPoints: [ScatterDataPoint] {
        [ScatterDataPoint(x: 0, y: 0, color: .normal)]
    }

    /// All functions (transformed to the correct time-space). These match the three types described by `allDataPoints`.`
    var allFunctionInfos: [FunctionDebugInfo] {
        []
    }

    /// The scatter strokables of all future bars (transformed to the correct time-space).
    // TODO: also previous bars!
    var barScatterStrokables: [BarScatterStrokable] {
        []
    }
}
