//
//  Created by David Knothe on 11.01.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Foundation

enum FramePhase: CaseIterable, Hashable {
    case frame
    case imageAnalysis
    case gameModelCollection
    case tapPrediction
}
