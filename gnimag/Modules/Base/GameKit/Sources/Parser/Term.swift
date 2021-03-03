//
//  Created by David Knothe on 25.03.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common

/// Use Term to evaluate an expression consisting of rational numbers.
public struct Term {
    public let string: String

    /// Default initializer.
    public init(string: String) {
        self.string = string
    }

    /// Parse and evaluate the term and return the result.
    /// Return nil if the term is ill-formed.
    /// Log errors if `verbose` is true.
    public func evaluate(verbose: Bool = false) -> RationalNumber? {
        guard let tokens = Tokenizer.tokenize(term: string) else {
            if verbose { Terminal.log(.error, "Couldn't tokenize expression \(string)!") }
            return nil
        }

        var parser = Parser(tokens: tokens)
        guard let expression = parser.parse() else {
            if verbose { Terminal.log(.error, "Couldn't parse expression \(string)!") }
            return nil
        }

        return expression.value
    }
}
