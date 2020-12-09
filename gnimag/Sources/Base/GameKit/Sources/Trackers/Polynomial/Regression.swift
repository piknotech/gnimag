//
//  Created by David Knothe on 09.04.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Surge

/// Regression encapsulates capabilities of calculating linear and polynomial regression, using Surge.
/// (Surge: https://github.com/mattt/Surge).
public enum Regression {
    /// Perform a polynomial regression and return a Polynomial.
    public static func polyRegression(x: [Double], y: [Double], n: Int) -> Polynomial {
        switch n {
        case 0:
            return Polynomial([mean(y)])
        case 1:
            let (a, b) = linregress(x, y)
            return Polynomial([b, a])
        default:
            return polyRegressionImp(x: x, y: y, n: n)
        }
    }

    /// Perform a linear regression and return a LinearFunction.
    public static func linearRegression(x: [Double], y: [Double]) -> LinearFunction {
        let (slope, intercept) = linregress(x, y)
        return LinearFunction(slope: slope, intercept: intercept)
    }
    
    // MARK: Implementation
    
    /// Perform a polynomial regression.
    /// Return the coefficients, beginning with the lowest one (x^0, x^1, ... x^n).
    private static func polyRegressionImp(x: [Double], y: [Double], n: Int) -> Polynomial {
        // Move regression frame
        let xShift = sum(x) / Double(x.count)
        let yShift = sum(x) / Double(y.count)
        let x = add(x, -xShift)
        let y = add(y, -yShift)

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
        let poly = Polynomial(reg[column: 0])

        return poly.shiftedLeft(by: -xShift) + yShift
    }
}
