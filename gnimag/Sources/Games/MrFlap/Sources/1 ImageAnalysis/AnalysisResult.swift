//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

/// The result that ImageAnalyzer will yield for each analyzed image.
/// It is a simple raw result; further processing is done by GameModelCollection.
struct AnalysisResult {
    let player: Player
    let playfield: Playfield
    let coloring: Coloring
    let bars: [Bar] // May be empty.

    var mode: GameMode {
        coloring.mode
    }
}

enum AnalysisError: Error {
    // The player position did not change.
    case samePlayerPosition

    // Player was not found.
    case error
}
