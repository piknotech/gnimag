//
//  Created by David Knothe on 24.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Cocoa
import Foundation

extension CGImage {
    /// Write the image to a given destination.
    public func write(to file: String) {
        let rep = NSBitmapImageRep(cgImage: self)
        let data = rep.representation(using: .png, properties: [:])!
        NSData(data: data).write(toFile: file, atomically: true)
    }

    /// Write the image to the users desktop.
    public func writeToDesktop(name: String) {
        let desktop = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first!
        write(to: desktop +/ name)
    }

    /// Read a CGImage from a PNG file.
    public static func from(path: String) -> CGImage? {
        guard let data = NSData(contentsOfFile: path),
            let dataProvider = CGDataProvider(data: data) else { return nil }
        return CGImage(pngDataProviderSource: dataProvider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }
}
