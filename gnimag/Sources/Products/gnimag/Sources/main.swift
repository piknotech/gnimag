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

let math = FreakingMath(imageProvider: Scrcpy.imageProvider, tapper: Scrcpy.tapper)
math.play()

RunLoop.main.run()
