//
//  Created by David Knothe on 07.10.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// Describes a smooth function whose domain and codomain are both the real numbers (represented by `Double`).
public protocol SmoothFunction {
    typealias Value = Double
    
    /// Calculate the value at a given point.
    func at(_ x: Value) -> Value

    /// The derivative, which is also smooth.
    var derivative: SmoothFunction { get }
}
