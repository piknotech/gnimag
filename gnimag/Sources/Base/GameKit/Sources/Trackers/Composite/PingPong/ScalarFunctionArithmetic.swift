//
//  Created by David Knothe on 26.10.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// A Function type which conforms to ScalarFunctionArithmetic provides additional arithmetic functionality like scalar multiplication and addition.
public protocol ScalarFunctionArithmetic: Function {
    static func +(f: Self, offset: Double) -> Self
    static func *(f: Self, factor: Double) -> Self
    
    func shiftLeft(by amount: Double) -> Self
}
