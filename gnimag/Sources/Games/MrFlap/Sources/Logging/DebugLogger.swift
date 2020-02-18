//
//  Created by David Knothe on 29.11.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import LoggingKit

final class DebugLogger: LoggingKit.DebugLogger<DebugParameters, DebugFrame> {
    /// One-time setup: create the logging directory.
    override func setup() {
        switch parameters.severity {
        case .alwaysText, .onErrors, .onErrorsTextOnly, .onIntegrityErrors:
            createCleanDirectory()

        case .none:
            break
        }
    }
}
