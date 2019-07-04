//
//  Created by David Knothe on 09.04.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Surge

/// Regression encapsulates capabilities of calculating linear and polynomial regression, using Surge.
/// (Surge: https://github.com/mattt/Surge).

public enum Regression {
    
    /// Perform a polynomial regression.
    public static func polyRegression(x: [Double], y: [Double], n: Int) -> Polynomial<Double> {
        switch n {
        case 0:
            return Polynomial([mean(y)])
        case 1:
            let (a, b) = linear(x: x, y: y)
            return Polynomial([b, a])
        default:
            let coefficients = polyRegressionImp(x: x, y: y, n: n)
            return Polynomial(coefficients)
        }
    }
    
    // MARK: Implementation
    
    /// Linear regression. (Much faster than performing a polynomial regression with n = 1).
    /// Return ax + b.
    private static func linear(x: [Double], y: [Double]) -> (a: Double, b: Double) {
        let meanx = mean(x)
        let meany = mean(y)
        let meanxy = mean(x .* y)
        let meanx_sqr = measq(x)
        
        // Calculate ax + b
        let slope = (meanx * meany - meanxy) / (meanx * meanx - meanx_sqr)
        let intercept = meany - slope * meanx
        
        return (slope, intercept)
    }
    
    /// Perform a polynomial regression.
    /// Return the coefficients, beginning with the lowest one (x^0, x^1, ... x^n).
    private static func polyRegressionImp(x: [Double], y: [Double], n: Int) -> [Double] {
        var xgrid = [[Double]]()
        
        // Construct (transposed) vandermonde matrix
        for i in 0 ... n {
            xgrid.append(pow(x, Double(i)))
        }
        
        let mx = Matrix(xgrid)
        
        // Construct y vector
        let my = Matrix(column: y)
        
        // Calculate coefficient vector
        let reg = inv(mx * transpose(mx)) * mx * my
        return reg[column: 0] // TOOD: oder row!
    }
}
