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
            if match(.CLASS) {
                return try classDeclaration()
            }
            if match(.FUN) {
                return try function(kind: "function")
            }
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
        if match(.FOR) {
            return try forStatement()
        }
        if match(.IF) {
            return try ifStatement()
        }
        if match(.PRINT) {
            return try printStatement()
        }
        if match(.RETURN) {
            return try returnStatement()
        }
        if match(.WHILE) {
            return try whileStatement()
        }
        if match(.LEFT_BRACE) {
            return .block(try blockStatement())
        }
        return try expressionStatement()
    }

    func forStatement() throws -> Statement {
        try consume(.LEFT_PAREN, message: "Expect '(' after 'for'.")

        // for consists of:
        // * initializer
        // * condition
        // * increment
        // all 3 are optional
        let initializer: Statement?
        if match(.SEMICOLON) {
            initializer = nil
        } else if match(.VAR) {
            initializer = try varDeclaration()
        } else {
            initializer = try expressionStatement()
        }

        let condition = check(.SEMICOLON) ? nil : try expression()
        try consume(.SEMICOLON, message: "Expect ';' after loop condition.")

        let increment = check(.RIGHT_PAREN) ? nil : try expression()
        try consume(.RIGHT_PAREN, message: "Expect ')' after for clauses.")

        var body = try statement()
        // if there's an increment, move it after the body
        // a for loop can be represented as a while loop
        // var a = 1
        // while a < 10
        //  ...
        //  a += 1
        if let increment = increment {
            body = .block([body, .expression(increment)])
        }
        // put the body inside a while loop
        body = .while(condition: condition ?? .literal(.bool(true)), body: body)
        // if there was an initializer, we move it BEFORE the while loop
        if let initializer = initializer {
            body = .block([initializer, body])
        }
        return body
    }

    func ifStatement() throws -> Statement {
        try consume(.LEFT_PAREN, message: "Expect '(' after 'if'.")
        let condition = try expression()
        try consume(.RIGHT_PAREN, message: "Expect ')' after 'if' condition.")

        let then = try statement()

        if match(.ELSE) {
            return .if(condition: condition, then: then, else: try statement())
        }

        return .if(condition: condition, then: then, else: nil)
    }

    func printStatement() throws -> Statement {
        let val = try expression()
        try consume(.SEMICOLON, message: "Expect ';' after value.")
        return .print(val)
    }

    func returnStatement() throws -> Statement {
        let keyword = previous() // this gives the return statement
        let value: Expression

        // returning values is optional
        if !check(.SEMICOLON) {
            value = try expression()
        } else {
            value = .empty
        }

        try consume(.SEMICOLON, message: "Expect ';' after return value.")
        return .return(keyword: keyword, value: value)
    }

    func whileStatement() throws -> Statement {
        try consume(.LEFT_PAREN, message: "Expect '(' after 'while'.")
        let condition = try expression()
        try consume(.RIGHT_PAREN, message: "Expect ')' after condition.")
        let body = try statement()
        return .while(condition: condition, body: body)
    }

    func blockStatement() throws -> [Statement] {
        var statements: [Statement] = []

        while (!check(.RIGHT_BRACE) && !isAtEnd) {
            statements.append(try declaration())
        }

        try consume(.RIGHT_BRACE, message: "Expect '}' after block")
        return statements
    }

    func expressionStatement() throws -> Statement {
        let expr = try expression()
        try consume(.SEMICOLON, message: "Expect ';' after expression.")
        return .expression(expr)
    }

    // kind param allows for reuse when we introduce classes
    func function(kind: String) throws -> Statement {
        // name of the function
        let name = try consume(.IDENTIFIER, message: "Expect \(kind) name.")
        try consume(.LEFT_PAREN, message: "Expect '(' after \(kind) name.")

        // params of the function
        var params: [Token] = []

        if !check(.RIGHT_PAREN) {
            repeat {
                if params.count >= 255 {
                    // don't throw the error
                    _ = error(token: peek(), message: "Can't have more than 255 arguments")
                }
                params.append(try consume(.IDENTIFIER, message: "Expect aparameter name."))
            } while match(.COMMA)
        }

        try consume(.RIGHT_PAREN, message: "Expect ')' after parameters.")

        // body of the function
        try consume(.LEFT_BRACE, message: "Expect '{' before \(kind) body.")
        return .function(name: name, params: params, body: try blockStatement())
    }

    func varDeclaration() throws -> Statement {
        let name = try consume(.IDENTIFIER, message: "Expect variable name.")

        let initializer: Expression
        if match(.EQUAL) {
            initializer = try expression()
        } else {
            initializer = .empty
        }

        try consume(.SEMICOLON, message: "Expect ';' after variable declaration.")
        return .variable(name: name, initializer: initializer)
    }

    func classDeclaration() throws -> Statement {
        let name = try consume(.IDENTIFIER, message: "Expect class name.")
        try consume(.LEFT_BRACE, message: "Expect '{' before class body.")

        var methods: [Statement] = []
        while !check(.RIGHT_BRACE) && !isAtEnd {
            methods.append(try function(kind: "method"))
        }

        try consume(.RIGHT_BRACE, message: "Expect '}' after class body.")
        return .class(name: name, methods: methods)
    }
}

private extension Parser {

    func expression() throws -> Expression {
        try assignment()
    }

    func assignment() throws -> Expression {
        let expression = try or()

        if match(.EQUAL) {
            let equals = previous()
            let value = try assignment()

            if case .variable(let name) = expression {
                return .assign(name: name, value: value)
            } else if case .get(let obj, let name) = expression {
                return .set(object: obj, name: name, value: value)
            }

            throw error(token: equals, message: "Invalid assignment target.")
        }

        return expression
    }

    func equality() throws -> Expression {
        var expression = try comparison()

        while match(.BANG_EQUAL, .EQUAL_EQUAL) {
            let op = previous()
            let rhs = try comparison()
            expression = .binary(lhs: expression, operator: op, rhs: rhs)
        }

        return expression
    }

    func or() throws -> Expression {
        var expression = try and()

        while match(.OR) {
            let op = previous()
            let rhs = try and()
            expression = .logical(lhs: expression, operator: op, rhs: rhs)
        }

        return expression
    }

    func and() throws -> Expression {
        var expression = try equality()

        while match(.AND) {
            let op = previous()
            let rhs = try equality()
            expression = .logical(lhs: expression, operator: op, rhs: rhs)
        }

        return expression
    }

    func comparison() throws -> Expression {
        var expression = try term()

        while match(.GREATER, .GREATER_EQUAL, .LESS, .LESS_EQUAL) {
            let op = previous()
            let rhs = try term()
            expression = .binary(lhs: expression, operator: op, rhs: rhs)
        }

        return expression
    }

    func term() throws -> Expression {
        var expression = try factor()

        while match(.MINUS, .PLUS) {
            let op = previous()
            let rhs = try factor()
            expression = .binary(lhs: expression, operator: op, rhs: rhs)
        }

        return expression
    }

    func factor() throws -> Expression {
        var expression = try unary()

        while match(.SLASH, .STAR) {
            let op = previous()
            let rhs = try unary()
            expression = .binary(lhs: expression, operator: op, rhs: rhs)
        }

        return expression
    }

    func unary() throws -> Expression {
        if match(.BANG, .MINUS) {
            let op = previous()
            let rhs = try unary() // recursive call
            return .unary(operator: op, rhs: rhs)
        }

        return try call()
    }

    func call() throws -> Expression {
        var expr = try primary()

        while true {
            if match(.LEFT_PAREN) {
                expr = try finishCall(expr)
            } else if match(.DOT) {
                let name = try consume(
                    .IDENTIFIER,
                    message: "Expect property name after '.'."
                )
                expr = .get(object: expr, name: name)
            } else {
                break
            }
        }

        return expr
    }

    func finishCall(_ callee: Expression) throws -> Expression {
        var arguments: [Expression] = []
        if !check(.RIGHT_PAREN) { // handle zero-arguments
            repeat {
                // no need for a limit, BUT
                // it simplifies bytecode interpreter
                if arguments.count >= 255 {
                    // don't throw the error
                    _ = error(token: peek(), message: "Can't have more than 255 arguments")
                }
                arguments.append(try expression())
            } while match(.COMMA)
        }

        let paren = try consume(.RIGHT_PAREN, message: "Expect ')' after arguments.")
        return .call(callee: callee, paren: paren, arguments: arguments)
    }

    func primary() throws -> Expression {
        if match(.FALSE) { return .literal(.bool(false)) }
        if match(.TRUE) { return .literal(.bool(true)) }
        if match(.NIL) { return .literal(.none) }

        if match(.NUMBER, .STRING) {
            // when a match is found, the idx advances by one
            // BEFORE returning
            // so we get the previous one, because that's the token
            // we just validated
            return .literal(previous().literal ?? .none)
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
