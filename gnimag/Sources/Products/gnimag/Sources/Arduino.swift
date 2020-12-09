//
//  Created by David Knothe on 05.05.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import ORSSerial
import Tapping

struct Arduino: SomewhereTapper {
    let port: ORSSerialPort

    /// Default initializer.
    init() {
        guard let port = ORSSerialPort(path: "/dev/cu.usbmodem14101") else {
            exit(withMessage: "Arduino not found.")
        }
        self.port = port
        port.open()
    }

    /// Tap on the screen.
    func tap() {
        let string = "A"
        port.send(string.data(using: .ascii)!)
    }
}

struct MultiTapper: SomewhereTapper {
    let tappers: [SomewhereTapper]

    /// Default initializer.
    init(_ tappers: SomewhereTapper...) {
        self.tappers = tappers
    }

    func tap() {
        tappers.forEach { $0.tap() }
    }
}
