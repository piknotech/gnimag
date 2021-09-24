//
//  Created by David Knothe on 22.09.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Foundation
import ORSSerial

/// A GRBLDevice represents a device, connected via a serial port, which is running GRBL v0.9 or above.
class GRBLDevice: NSObject {
    private let port: ORSSerialPort
    private var responseEvaluator = ResponseEvaluator()

    /// True after the welcome message (Grbl X.Xx) has been sent.
    private(set) var isInitialized = false
    let initialized = Event<Void>()

    /// True when the device is currently moving.
    private(set) var isMoving = false
    private var movementCallback: (() -> Void)?

    /// True when the device has been closed or removed from the system.
    private(set) var isRemoved = false

    /// Default initializer. Opens the given port.
    init(path: String) {
        guard let port = ORSSerialPort(path: path) else {
            exit(withMessage: "GRBLDevice not found on \(path).")
        }

        self.port = port
        super.init()
        port.delegate = self
        port.baudRate = 115200
        port.open()

        TerminationHandler.shared.onTerminate += {
            Timing.shared.perform(after: 0.25) {
                self.port.close()
            }
        }

        responseEvaluator.callback = receivedResponse(response:)
    }

    /// Move to a point, given in absolute coordinates.
    /// Attention: Only call when `moving = false`. If `moving`, this is a no-op.
    /// `callback` is called when the movement has ended, given that `moving = false`.
    func move(to point: CGPoint, callback: (() -> Void)? = nil) {
        guard !isMoving else { return }

        isMoving = true
        movementCallback = callback

        let str = String(format: "X%.2fY%.2f\n", point.y, point.x) // X and Y are switched from our perspective
        send(str)
    }

    private func requestState() {
        send("?")
    }

    private func send(_ str: String) {
        port.send(str.data(using: .utf8)!)
    }
}

extension GRBLDevice: ORSSerialPortDelegate {
    // MARK: Message Handling
    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        guard port == serialPort else { return }

        guard let response = String(data: data, encoding: .utf8) else { return }
        responseEvaluator.add(response)
    }

    private func receivedResponse(response: ResponseEvaluator.ResponseType) {
        switch response {
        case .welcome:
            isInitialized = true
            initialized.trigger()

        case .idle where isMoving:
            isMoving = false
            movementCallback?()

        case .ok where isMoving, .running where isMoving:
            Timing.shared.perform(after: 0.1) { // Don't stress the microcontroller too much
                self.requestState()
            }

        case .other(let message):
            print("GRBLDevice received message: \(message)")
            if isMoving { requestState()}

        default: ()
        }
    }

    // MARK: Removal
    func serialPortWasClosed(_ serialPort: ORSSerialPort) {
        guard port == serialPort else { return }
        isRemoved = true
    }

    func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
        guard port == serialPort else { return }
        isRemoved = true
    }

    func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
        guard port == serialPort else { return }
        print("Serial Port Error:", error)
    }
}

/// ResponseEvaluator collects and evaluates responses coming from a GRBLDevice.
private struct ResponseEvaluator {
    private var currentMessage = ""

    enum ResponseType {
        case welcome
        case ok
        case idle
        case running
        case other(String)

        fileprivate var prefix: String {
            switch self {
            case .welcome: return "Grbl"
            case .ok: return "ok"
            case .idle: return "<Idle"
            case .running: return "<Run"
            case .other: return ""
            }
        }
    }

    var callback: ((ResponseType) -> Void)?

    /// Call when a new message part arrives.
    /// Full messages always terminate with a newline - if `part` contains a newline, `callback` is executed with the appropriate argument, depending on `currentMessage` and `part`.
    mutating func add(_ part: String) {
        if part.contains("\n") {
            var parts = part.split(separator: "\n", maxSplits: 1)
            currentMessage += String(parts.removeFirst())
            evaluate()
            currentMessage = parts.joined()
        } else {
            currentMessage += part
        }
    }

    mutating private func evaluate() {
        currentMessage = currentMessage.trimmingCharacters(in: .whitespacesAndNewlines)

        for type in [ResponseType.welcome, .ok, .idle, .running] {
            if currentMessage.starts(with: type.prefix) {
                currentMessage = ""
                callback?(type)
            }
        }

        if !currentMessage.isEmpty {
            callback?(.other(currentMessage))
        }
    }
}
