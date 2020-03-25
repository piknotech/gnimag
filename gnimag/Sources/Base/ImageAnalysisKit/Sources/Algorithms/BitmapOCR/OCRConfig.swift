//
//  Created by David Knothe on 25.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation

/// OCRConfig describes the contents of a configuration file that the user can optionally use for configuration.
/// The configuration must be inside the OCR folder and must be named "ocr.json".
internal struct OCRConfig: Decodable {
    /// Mappings from filenames to character names. For example, "plus" (from plus.png) could be mapped to the character "+".
    /// For filenames where no mapping is given, the filename is simply used as the character. For example, "1.png" will, by default, be mapped to "1".
    let mappings: [String: String]

    /// Try reading an OCRConfig from a given JSON file.
    static func from(file: String) -> OCRConfig? {
        guard FileManager.default.fileExists(atPath: file) else { return nil }

        guard let data = NSData(contentsOfFile: file), let config = try? JSONDecoder().decode(OCRConfig.self, from: Data(data)) else {
            exit(withMessage: "BitmapOCR – Couldn't read config file \(file)!")
        }

        return config
    }
}
