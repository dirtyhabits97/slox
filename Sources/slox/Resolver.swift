//
//  File.swift
//  
//
//  Created by user on 28/08/21.
//

import Foundation

final class Resolver {

    private let interpreter: Interpreter
    private var currentFunction = FunctionStatus.none
    // The scope is a stack
    private var scopes: [[String: Bool]] = []


    init(interpreter: Interpreter) {
        self.interpreter = interpreter
    }

    func resolve(_ statements: [Statement]) {
        for stmt in statements {
            resolve(stmt)
        }
    }
}

// MARK: - Statements

private extension Resolver {

    func resolve(_ statement: Statement) {
        do {
            switch statement {
            case .block(let statements):
                try visitBlockStatement(statements)
            case .class(name: let name, methods: let methods):
                try visitClassStatement(name, methods)
            case .expression(let expr):
                try visitExpressionStatement(expr)
            case .function(name: let name, params: let params, body: let body):
                try visitFunctionStatement(name, params, body)
            case .if(condition: let condition, then: let thenBranch, else: let elseBranch):
                try visitIfStatement(condition, thenBranch, elseBranch)
            case .print(let expr):
                try visitPrintStatement(expr)
            case .return(keyword: let keyword, value: let value):
                try visitReturnStatement(keyword, value)
            case .variable(name: let name, initializer: let initializer):
                try visitVariableStatement(name, initializer)
            case .while(condition: let condition, body: let body):
                try visitWhileStatement(condition, body)
            }
        } catch {
            // fail silently
        }

    }
}

extension Resolver: StatementVisitor {

    func visitBlockStatement(
        _ statements: [Statement]
    ) throws {
        beginScope()
        resolve(statements)
        endScope()
    }

    func visitClassStatement(
        _ name: Token,
        _ methods: [Statement]
    ) throws {
        declare(name)
        define(name)
    }

    func visitExpressionStatement(
        _ expr: Expression
    ) throws {
        resolve(expr)
    }

    func visitFunctionStatement(
        _ name: Token,
        _ params: [Token],
        _ body: [Statement]
    ) throws {
        declare(name)
        define(name)
        // TODO: consider moving this to another function
        let enclosingFunction = currentFunction
        currentFunction = .some
        defer { currentFunction = enclosingFunction }
        beginScope()
        for param in params {
            declare(param)
            define(param)
        }
        resolve(body)
        endScope()
    }

    func visitIfStatement(
        _ condition: Expression,
        _ thenBranch: Statement,
        _ elseBranch: Statement?
    ) throws {
        resolve(condition)
        resolve(thenBranch)
        if let elseBranch = elseBranch {
            resolve(elseBranch)
        }
    }

    func visitPrintStatement(
        _ expr: Expression
    ) throws {
        resolve(expr)
    }

    func visitReturnStatement(
        _ keyword: Token,
        _ value: Expression
    ) throws {
        if currentFunction == .none {
            Lox.error(token: keyword, message: "Can't return from top-level code.")
        }
        resolve(value)
    }

    func visitVariableStatement(
        _ name: Token,
        _ initializer: Expression
    ) throws {
        declare(name)
        resolve(initializer)
        define(name)
    }

    func visitWhileStatement(
        _ condition: Expression,
        _ body: Statement
    ) throws {
        resolve(condition)
        resolve(body)
    }
}

// MARK: - Expressions

private extension Resolver {

    func resolve(_ expression: Expression) {
        do {
            switch expression {
            case .assign(name: let name, value: let value):
                resolveAssignExpression(name, value, expression)
            case .binary(lhs: let lhs, operator: let op, rhs: let rhs):
                try visitBinaryExpression(lhs, op, rhs)
            case .call(callee: let callee, paren: let paren, arguments: let args):
                try visitCallExpression(callee, paren, args)
            case .empty:
                try visitEmptyExpression()
            case .get(object: let obj, name: let name):
                try visitGetExpression(obj, name)
            case .grouping(let expr):
                try visitGroupExpression(expr)
            case .literal(let lit):
                try visitLiteralExpression(lit)
            case .logical(lhs: let lhs, operator: let op, rhs: let rhs):
                try visitLogicalExpression(lhs, op, rhs)
            case .unary(operator: let op, rhs: let rhs):
                try visitUnaryExpression(op, rhs)
            case .variable(let name):
                resolveVariableExpression(name, expression)
            }
        } catch {
            // fail silently
        }
    }

    func resolveAssignExpression(
        _ name: Token,
        _ value: Expression,
        _ expr: Expression
    ) {
        resolve(value)
        resolveLocal(expr, name: name)
    }

    func resolveVariableExpression(
        _ name: Token,
        _ expr: Expression
    ) {
        if !scopes.isEmpty && scopes.last?[name.lexeme] == false {
            Lox.error(token: name, message: "Can't read local variable in its own initiazlier.")
        }
        resolveLocal(expr, name: name)
    }
}

extension Resolver: ExpressionVisitor {

    func visitAssignExpression(
        _ name: Token,
        _ value: Expression
    ) throws {
        fatalError("Not implemented. Refer to `resolveAssignExpression(_:_:_:)`.")
    }

    func visitBinaryExpression(
        _ lhs: Expression,
        _ operation: Token,
        _ rhs: Expression
    ) throws {
        resolve(lhs)
        resolve(rhs)
    }

    func visitCallExpression(
        _ callee: Expression,
        _ paren: Token,
        _ arguments: [Expression]
    ) throws {
        resolve(callee)
        arguments.forEach(resolve(_:))
    }

    func visitEmptyExpression() throws -> () {
        // do nothing
    }

    func visitGetExpression(
        _ object: Expression,
        _ name: Token
    ) throws {
        resolve(object)
    }

    func visitGroupExpression(
        _ expr: Expression
    ) throws {
        resolve(expr)
    }

    func visitLiteralExpression(
        _ literal: Literal
    ) throws {
        // do nothing
    }

    func visitLogicalExpression(
        _ lhs: Expression,
        _ operation: Token,
        _ rhs: Expression
    ) throws {
        resolve(lhs)
        resolve(rhs)
    }

    func visitUnaryExpression(
        _ operation: Token,
        _ rhs: Expression
    ) throws {
        resolve(rhs)
    }

    func visitVariableExpression(
        _ name: Token
    ) throws -> () {
        fatalError("Not implemented. Refer to `resolveVariableExpression(_:_:)`.")
    }
}

// MARK: - Helpers

private extension Resolver {

    func resolveLocal(_ expr: Expression, name: Token) {
        for (idx, scope) in scopes.lazy.enumerated().reversed() where scope[name.lexeme] != nil {
            interpreter.resolve(expr, depth: scope.count - 1 - idx)
            return
        }
    }
}

private extension Resolver {

    func beginScope() {
        scopes.append([:])
    }

    func endScope() {
        scopes.removeLast()
    }
}

private extension Resolver {

    func declare(_ token: Token) {
        if scopes.isEmpty { return }
        // mark it as "not ready yet"
        // false if we haven't finished resolving that var's initializer
        if scopes.last?[token.lexeme] != nil {
            Lox.error(
                token: token,
                message: "Already a variable with this name in this scope."
            )
        }
        scopes[scopes.count - 1][token.lexeme] = false
    }

    func define(_ token: Token) {
        if scopes.isEmpty { return }
        // mark the var as resolved
        scopes[scopes.count - 1][token.lexeme] = true
    }
}

// MARK: - Top level return
// Don't allow the user to use `return` in the global scope

private extension Resolver {

    enum FunctionStatus {
        case none
        case some
    }
}
