//
//  Created by David Knothe on 25.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common

struct Term {
    let string: String

    /// Parse and evaluate the term and return the result.
    /// Return nil if the term is ill-formed.
    func evaluate() -> RationalNumber? {
        guard let tokens = Tokenizer.tokenize(term: string) else {
            Terminal.log(.error, "Couldn't tokenize expression \(string)!")
            return nil
        }

        var parser = Parser(tokens: tokens)
        guard let expression = parser.parse() else {
            Terminal.log(.error, "Couldn't parse expression \(string)!")
            return nil
        }

        return expression.value
    }
}
