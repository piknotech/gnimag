//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// The result that ImageAnalyzer will yield for each analyzed image.
/// It is a simple raw result; further processing is done by GameModelCollection.
struct AnalysisResult {
    let player: Player
    let playfield: Playfield
    let coloring: Coloring
    let bars: [Bar] // May be empty.
}

enum AnalysisError: Error {
    case playfieldNotFound
    case playerNotFound
    case unspecified
}
