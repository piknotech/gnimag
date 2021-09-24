//
//  Created by David Knothe on 05.05.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Foundation
import ORSSerial
import Tapping

/// A SingleByteArduino sends a single byte to a connected Arduino via USB each time when a tap shall be performed.
/// In addition, it has the option to only move the tip down or up. A tap consists of both down- and up-movements.
class SingleByteArduino: SomewhereTapper {
    let port: ORSSerialPort

    /// Default initializer. Opens the given port.
    init(portPath: String) {
        guard let port = ORSSerialPort(path: portPath) else {
            exit(withMessage: "Arduino not found on \(portPath).")
        }
        self.port = port
        port.baudRate = 9600
        port.open()

        TerminationHandler.shared.onTerminate += {
            Timing.shared.perform(after: 0.25) {
                print("close")
                self.port.close()
            }
        }
    }

    /// Tap on the screen by sending a single byte to the Arduino.
    func tap() {
        port.send("c".data(using: .ascii)!)
    }

    /// Move the pen tip down so it touches the screen.
    func down() {
        port.send("d".data(using: .ascii)!)
    }

    /// Lift the pen tip from the screen.
    func up() {
        port.send("u".data(using: .ascii)!)
    }

    /// All currently connected/available ports.
    static var availablePorts: [String] {
        ORSSerialPortManager.shared().availablePorts.map(\.path)
    }
}
