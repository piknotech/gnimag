//
//  Created by David Knothe on 06.02.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

/// PredictionFrame bundles all properties (i.e. simplified models) that are relevant for a single frame of tap prediction.
struct PredictionFrame {
    let interaction: PlayerBarInteraction
    let player: PlayerProperties
    let playfield: PlayfieldProperties
    let bar: BarProperties
    let jumping: JumpingProperties
    let currentTime: Double
}
