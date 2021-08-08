//
//  File.swift
//  
//
//  Created by user on 7/08/21.
//

import Foundation

final class Parser {

    private let tokens: [Token]
    private var current = 0

    init(tokens: [Token]) {
        self.tokens = tokens
    }

    func parse() -> Expr? {
        do { // TODO: revisit this method
            return try expression()
        } catch {
            return nil
        }
    }
}

private extension Parser {


    func expression() throws -> Expr {
        try equality()
    }

    func equality() throws -> Expr {
        var expression = try comparison()

        while match(.BANG_EQUAL, .EQUAL_EQUAL) {
            let op = previous()
            let rhs = try comparison()
            expression = .binary(lhs: expression, operator: op, rhs: rhs)
        }

        return expression
    }

    func comparison() throws -> Expr {
        var expression = try term()

        while match(.GREATER, .GREATER_EQUAL, .LESS, .LESS_EQUAL) {
            let op = previous()
            let rhs = try term()
            expression = .binary(lhs: expression, operator: op, rhs: rhs)
        }

        return expression
    }

    func term() throws -> Expr {
        var expression = try factor()

        while match(.MINUS, .PLUS) {
            let op = previous()
            let rhs = try factor()
            expression = .binary(lhs: expression, operator: op, rhs: rhs)
        }

        return expression
    }

    func factor() throws -> Expr {
        var expression = try unary()

        while match(.SLASH, .STAR) {
            let op = previous()
            let rhs = try unary()
            expression = .binary(lhs: expression, operator: op, rhs: rhs)
        }

        return expression
    }

    func unary() throws -> Expr {
        if match(.BANG, .MINUS) {
            let op = previous()
            let rhs = try unary() // recursive call
            return .unary(operator: op, rhs: rhs)
        }

        return try primary()
    }

    func primary() throws -> Expr {
        if match(.FALSE) { return .literal(false) }
        if match(.TRUE) { return .literal(true) }
        if match(.NIL) { return .literal(nil) }

        if match(.NUMBER, .STRING) {
            return .literal(previous().literal)
        }

        if match(.LEFT_PAREN) {
            let expression = try expression()
            try consume(.RIGHT_PAREN, message: "Expect ')' after expression.")
            return .grouping(expression)
        }

        throw error(token: peek(), message: "Expect expression.")
    }

    @discardableResult
    func consume(_ type: TokenType, message: String) throws -> Token {
        if check(type) { advance() }

        throw error(token: peek(), message: message)
    }
}

private extension Parser {

    // TODO: we'll use this one later
    func syncronize() {
        advance()

        while !isAtEnd {
            if previous().type == .SEMICOLON { return }

            switch peek().type {
            case .CLASS, .FUN, .VAR, .FOR, .IF, .WHILE, .PRINT, .RETURN:
                return
            default:
                advance()
            }
        }
    }
}

private extension Parser {

    func error(token: Token, message: String) -> Error {
        Lox.error(token: token, message: message)
        return Error()
    }

    struct Error: Swift.Error {

    }
}

private extension Parser {

    func match(_ tokenTypes: TokenType...) -> Bool {
        for type in tokenTypes {
            if check(type) {
                advance()
                return true
            }
        }

        return false
    }

    private var isAtEnd: Bool { peek().type == .EOF }

    func peek() -> Token {
        tokens[current]
    }

    func previous() -> Token {
        tokens[current - 1]
    }

    func check(_ type: TokenType) -> Bool {
        if isAtEnd { return false }
        return peek().type == type
    }

    @discardableResult
    func advance() -> Token {
        if !isAtEnd { current += 1 }
        return previous()
    }
}
