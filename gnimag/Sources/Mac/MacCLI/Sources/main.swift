import Foundation
import MacTestingTools
import MrFlap

let provider = ImageListProvider(directoryPath: "/Users/David/Desktop/Fun/gnimag-test/TestRun", framerate: 1, imageFromCGImage: NativeImage.init)
provider.start()
let tapper = WindowTapper(appName: "Fork")
let mrflap = MrFlap(imageProvider: provider, tapper: tapper)
mrflap.play()

RunLoop.main.run()
