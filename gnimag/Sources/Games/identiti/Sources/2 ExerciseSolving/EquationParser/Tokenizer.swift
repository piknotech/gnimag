//
//  Created by David Knothe on 25.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation

/// Tokenizer splits an equation string into tokens, i.e. numbers and operators.
enum Tokenizer {
    /// Tokenize the equation string. Return nil when an unallowed character is encountered.
    static func tokenize(equation: String) -> [Token]? {
        var scanner = ArrayScanner(array: Array(equation)) // Split equation into unicode characters
        var result = [Token]()

        while let character = scanner.next() {
            // Found character: convert directly to token
            if Token.isOperatorSymbol(character) {
                let token = Token(operator: character)
                result.append(token)
            }

            // Found digit: consume the string until not finding a digit anymore
            else if Token.isDigit(character) {
                var numberString = String(character)
                while let next = scanner.peakNext(), Token.isDigit(next) {
                    numberString.append(next)
                    scanner.next() // Move forward
                }
                let token = Token(number: numberString)
                result.append(token)
            }

            // Invalid character – fail tokenization
            else {
                return nil
            }
        }

        return result
    }
}

enum Token {
    case number(Int)
    case plus
    case minus
    case times
    case divide
    case leftParen
    case rightParen

    /// States whether the given character is a valid operator.
    static func isOperatorSymbol(_ character: Character) -> Bool {
        "+-*/()".contains(character)
    }

    /// States whether the given character is a digit.
    static func isDigit(_ character: Character) -> Bool {
        "0123456789".contains(character)
    }

    /// Create Token from a valid (!) operator character.
    init(operator: Character) {
        switch `operator` {
        case "+":
            self = .plus
        case "-":
            self = .minus
        case "*":
            self = .times
        case "/":
            self = .divide
        case "(":
            self = .leftParen
        case ")":
            self = .rightParen
        default:
            fatalError("Invalid usage of Token!")
        }
    }

    /// Create Token from a valid (!) number string.
    init(number: String) {
        guard let value = Int(number) else {
            fatalError("Invalid usage of Token!")
        }
        self = .number(value)
    }
}
