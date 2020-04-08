import Common
import Foundation
import Image
import ImageAnalysisKit
import TestingTools
import MrFlap
import YesNoMathGames
import FlowFree
import Geometry
import Tapping

let flow = FlowFreeTimeTrial(imageProvider: Scrcpy.imageProvider, dragger: Scrcpy.dragger)
flow.play()

RunLoop.main.run()
