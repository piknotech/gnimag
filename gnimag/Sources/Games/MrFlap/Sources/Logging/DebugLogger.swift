//
//  Created by David Knothe on 29.11.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import Foundation
import LoggingKit

final class DebugLogger: LoggingKit.DebugLogger<DebugParameters, DebugLoggerFrame> {
    override func setup() {
        createDirectory()
    }

    // Delete, if required, and then recreate the logging directory.
    private func createDirectory() {
        switch parameters.severity {
        case .alwaysText, .onErrors, .textOnly:
            // Empty folder without deleting it (retaining attributes like desktop position and icon)
            let items = (try? FileManager.default.contentsOfDirectory(atPath: parameters.location)) ?? []
            for item in items where item != "Icon\r" { // Retain folder icon
                try? FileManager.default.removeItem(atPath: parameters.location +/ item)
            }

            try! FileManager.default.createDirectory(atPath: parameters.location, withIntermediateDirectories: true)

        case .none:
            break
        }
    }
}
