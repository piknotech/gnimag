//
//  Created by David Knothe on 13.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import AppKit
import Common
import Foundation
import Image

extension MrFlapGameSimulation {
    /// Call this to create a window (passively) showing the live game simulation.
    /// This is a blocking call.
    public func runAsApplication() {
        let delegate = AppDelegate(game: self)
        newFrame += { image, _ in
            delegate.set(image: image)
        }

        // Run application
        let app = NSApplication.shared
        app.delegate = delegate
        app.run()
    }
}

/// An AppDelegate objects opening a window and providing a method to update the window with the current image.
private class AppDelegate: NSObject, NSApplicationDelegate {
    private let window: NSWindow

    init(game: MrFlapGameSimulation) {
        window = NSWindow(
            contentRect: NSMakeRect(200, 200, game.screenSize.width, game.screenSize.height),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.contentView!.wantsLayer = true
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        window.makeKeyAndOrderFront(nil)
    }

    /// Show an image on the window.
    func set(image: Image) {
        window.contentView?.layer!.contents = image.CGImage!
    }
}
