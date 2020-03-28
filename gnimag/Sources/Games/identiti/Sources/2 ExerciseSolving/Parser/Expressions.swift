//
//  Created by David Knothe on 26.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

/// An expression which evaluates to an integer value.
protocol Expression {
    /// Evaluate the expression and return the result.
    var value: RationalNumber { get }
}

struct Number: Expression {
    let value: RationalNumber
}

struct Operation: Expression {
    let type: OperationType
    enum OperationType {
        case plus
        case minus
        case times
        case divide
    }

    let left: Expression
    let right: Expression

    /// Evaluate the expression and return the result.
    var value: RationalNumber {
        switch type {
        case .plus:
            return left.value + right.value
        case .minus:
            return left.value - right.value
        case .times:
            return left.value * right.value
        case .divide:
            return left.value / right.value
        }
    }
}
