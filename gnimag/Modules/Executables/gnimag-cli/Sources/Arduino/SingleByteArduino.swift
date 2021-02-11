//
//  Created by David Knothe on 05.05.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Foundation
import ORSSerial
import Tapping

/// A SingleByteArduino sends a single byte to a connected Arduino via USB each time when a tap shall be performed.
struct SingleByteArduino: SomewhereTapper {
    let port: ORSSerialPort

    /// Default initializer.
    init(portPath: String) {
        guard let port = ORSSerialPort(path: portPath) else {
            exit(withMessage: "Arduino not found.")
        }
        self.port = port
        port.open()
    }

    /// Tap on the screen by sending a single byte to the Arduino.
    func tap() {
        port.send(Data([1]))
    }

    /// All currently connected/available ports.
    static var availablePorts: [String] {
        ORSSerialPortManager.shared().availablePorts.map(\.path)
    }
}
