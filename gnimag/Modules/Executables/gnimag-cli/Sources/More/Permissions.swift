//
//  Created by David Knothe on 07.03.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import ApplicationServices
import Common
import CoreGraphics
import CoreVideo

enum Permissions {
    /// Determine whether gnimag has the required security permissions (accessibility and screen recording). If not, exit with a respective message.
    static func checkOnStartup() {
        let accessibility = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeRetainedValue(): kCFBooleanTrue] as CFDictionary)

        let screenRecording = CGDisplayStream(
            dispatchQueueDisplay: CGMainDisplayID(),
            outputWidth: 1,
            outputHeight: 1,
            pixelFormat: Int32(kCVPixelFormatType_32BGRA),
            properties: nil,
            queue: DispatchQueue.global(),
            handler: { _, _, _, _ in }
        ) != nil

        if accessibility && screenRecording {
            // Everything good
        }
        else {
            let message = """
            gnimag requires several permissions in order to receive screen input.
            Open Settings.app > Security > Privacy, then enable:
            • Accessibility
            • Screen Recording
            • Files and Folders: when you use additional gnimag features like DebugLogging, ImageListProvider etc., you will need file and folder access.
            Enable these permissions for both gnimag and Terminal (depending on from where you run gnimag, you need one or the other).
            """

            print(message)
            exit(1)
        }
    }
}
