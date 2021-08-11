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

    func parse() -> [Statement] {
        var statements: [Statement] = []
        
        do {
            while !isAtEnd {
                statements.append(try declaration())
            }
        } catch {
            // TODO: handle error
        }

        return statements
    }
}

private extension Parser {

    func declaration() throws -> Statement {
        do {
            if match(.VAR) {
                return try varDeclaration()
            }
            return try statement()
        } catch {
            syncronize()
            throw error
        }
    }

    func statement() throws -> Statement {
        if match(.PRINT) {
            return try printStatement()
        }
        if match(.LEFT_BRACE) {
            return .block(try blockStatement())
        }
        return try expressionStatement()
    }

    func blockStatement() throws -> [Statement] {
        var statements: [Statement] = []

        while (!check(.RIGHT_BRACE) && !isAtEnd) {
            statements.append(try declaration())
        }

        try consume(.RIGHT_BRACE, message: "Expect '}' after block")
        return statements
    }

    func printStatement() throws -> Statement {
        let val = try expression()
        try consume(.SEMICOLON, message: "Expect ';' after value.")
        return .print(val)
    }

    func expressionStatement() throws -> Statement {
        let expr = try expression()
        try consume(.SEMICOLON, message: "Expect ';' after expression.")
        return .expression(expr)
    }

    func varDeclaration() throws -> Statement {
        let name = try consume(.IDENTIFIER, message: "Expect variable name.")

        let initializer: Expr
        if match(.EQUAL) {
            initializer = try expression()
        } else {
            initializer = .empty
        }

        try consume(.SEMICOLON, message: "Expect ';' after variable declaration.")
        return .variable(name: name, initializer: initializer)
    }
}

private extension Parser {

    func expression() throws -> Expr {
        try assignment()
    }

    func assignment() throws -> Expr {
        let expression = try equality()

        if match(.EQUAL) {
            let equals = previous()
            let value = try assignment()

            if case .variable(let name) = expression {
                return .assign(name: name, value: value)
            }

            throw error(token: equals, message: "Invalid assignment target.")
        }

        return expression
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
        if match(.FALSE) { return .literal(bool: false) }
        if match(.TRUE) { return .literal(bool: true) }
        if match(.NIL) { return .literal(nil) }

        if match(.NUMBER, .STRING) {
            // when a match is found, the idx advances by one
            // BEFORE returning
            // so we get the previous one, because that's the token
            // we just validated
            return .literal(previous().literal)
        }

        if match(.IDENTIFIER) {
            return .variable(previous())
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
        if check(type) { return advance() }

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
