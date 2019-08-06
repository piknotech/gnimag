//
//  Created by David Knothe on 06.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Cocoa

extension CGImage {
    /// Write the image to a given destination.
    func write(to filename: String) {
        let rep = NSBitmapImageRep(cgImage: self)
        let data = rep.representation(using: .png, properties: [:])!
        NSData(data: data).write(toFile: filename, atomically: true)
    }
}
