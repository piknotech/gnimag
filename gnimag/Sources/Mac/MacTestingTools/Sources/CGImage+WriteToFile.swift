//
//  Created by David Knothe on 06.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Cocoa

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
        write(to: desktop + "/" + name)
    }
}
