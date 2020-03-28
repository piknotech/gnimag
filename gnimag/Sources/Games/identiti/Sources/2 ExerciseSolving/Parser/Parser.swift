//
//  Created by David Knothe on 26.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation

/// Parser converts a stream of Tokens into an AST (i.e. a (recursive) top-level Expression instance).
/// Each parser can only be used once to parse any expression.
/// Attention: Mulitplication and division is right-associative, i.e. ambiguous expressions with like `1/2*3` will be parsed as `1/(2*3)`. Addition and substraction on the other hand is left-associative.
struct Parser {
    /// The stream of tokens.
    private var tokens: ArrayScanner<Token>

    /// Default initializer.
    init(tokens: [Token]) {
        self.tokens = ArrayScanner(array: tokens)
    }

    /// Parse the exprssion. Return nil when a syntax error is encountered.
    /// Each parser can only be used once to parse any expression.
    mutating func parse() -> Expression? {
        parseExpression()
    }

    // MARK: Resursive Descent Implementation
    // (This closely follows the lecture notes: Programmierparadigmen by Prof. Dr.-Ing. G. Snelting, ©2010–2018 by IPD Snelting)
    // The (left-recursion-free) simple SLL(1)-grammar is as follows:
    // Expr -> Term Expr'
    // Expr' -> + Term Expr' | - Term Expr' | ε
    // Term -> Factor Term'
    // Term' -> * Factor Term' | / Factor Term' | ε
    // Factor -> number | ( Expr )

    /// Parse an Expr.
    private mutating func parseExpression() -> Expression? {
        guard let term = parseTerm() else { return nil }
        return parseExpressionPrime(term)
    }

    /// Parse an Expr'.
    private mutating func parseExpressionPrime(_ expr: Expression) -> Expression? {
        switch tokens.peakNext() {
        case .plus:
            tokens.next()
            guard let right = parseTerm() else { return nil }
            let expr = Operation(type: .plus, left: expr, right: right)
            return parseExpressionPrime(expr)

        case .minus:
            tokens.next()
            guard let right = parseTerm() else { return nil }
            let expr = Operation(type: .minus, left: expr, right: right)
            return parseExpressionPrime(expr)

        case .rightParen, .none:
            return expr

        default:
            return nil
        }
    }

    /// Parse a Term.
    private mutating func parseTerm() -> Expression? {
        guard let term = parseFactor() else { return nil }
        return parseTermPrime(term)
    }

    /// Parse a Term'.
    private mutating func parseTermPrime(_ expr: Expression) -> Expression? {
        switch tokens.peakNext() {
        case .times:
            tokens.next()
            guard let right = parseTerm() else { return nil }
            let expr = Operation(type: .times, left: expr, right: right)
            return parseTermPrime(expr)

        case .divide:
            tokens.next()
            guard let right = parseTerm() else { return nil }
            let expr = Operation(type: .divide, left: expr, right: right)
            return parseTermPrime(expr)

        case .plus, .minus, .rightParen, .none:
            return expr

        default:
            return nil
        }
    }

    /// Parse a Factor.
    private mutating func parseFactor() -> Expression? {
        switch tokens.peakNext() {
        case let .number(value):
            tokens.next()
            return Number(value: RationalNumber(num: value, denom: 1))

        case .leftParen:
            tokens.next()
            guard let expr = parseExpression() else { return nil }
            guard case .rightParen = tokens.next() else { return nil }
            return expr

        default:
            return nil
        }
    }
}
