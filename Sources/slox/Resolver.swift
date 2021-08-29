//
//  File.swift
//  
//
//  Created by user on 28/08/21.
//

import Foundation

final class Resolver {

    private let interpreter: Interpreter
    // The scope is a stack
    private var scopes: [[String: Bool]] = []

    init(interpreter: Interpreter) {
        self.interpreter = interpreter
    }
}

private extension Resolver {

    func resolve(_ statements: [Statement]) {
        for stmt in statements {
            resolve(stmt)
        }
    }

    func resolve(_ statement: Statement) {
        switch statement {
        case .block(let statements):
            resolveBlockStatement(statements)
        case .variable(name: let name, initializer: let initializer):
            resolveVarStatement(name, initializer)
        case .function(name: let name, params: let params, body: let body):
            resolveFunctionStatement(name, params, body)
        case .expression(let expr), .print(let expr), .return(keyword: _, value: let expr):
            resolve(expr)
        case .if(condition: let condition, then: let thenStatement, else: let elseStatement):
            resolveIfStatement(condition, thenStatement: thenStatement, elseStatement: elseStatement)
        case .while(condition: let condition, body: let body):
            resolveWhileStatement(condition, body)
        }
    }

    func resolveWhileStatement(
        _ condition: Expression,
        _ body: Statement
    ) {
        resolve(condition)
        resolve(body)
    }

    func resolveIfStatement(
        _ condition: Expression,
        thenStatement: Statement,
        elseStatement: Statement?
    ) {
        resolve(condition)
        resolve(thenStatement)
        if let elseStatement = elseStatement {
            resolve(elseStatement)
        }
    }

    func resolveFunctionStatement(_ name: Token, _ params: [Token], _ body: [Statement]) {
        declare(name)
        define(name)
        // TODO: consider moving this to another function
        beginScope()
        for param in params {
            declare(param)
            define(param)
        }
        resolve(body)
        endScope()
    }

    func resolveBlockStatement(_ stmts: [Statement]) {
        beginScope()
        resolve(stmts)
        endScope()
    }

    func resolveVarStatement(_ name: Token, _ initializer: Expression) {
        declare(name)
        resolve(initializer)
        define(name)
    }
}

private extension Resolver {

    func resolve(_ expression: Expression) {
        switch expression {
        case .variable(let token):
            resolveVarExpression(token, expression)
        case .assign(name: let name, value: let value):
            resolveAssignExpression(name, value, expression)
        case .call(callee: let callee, paren: _, arguments: let args):
            resolveCallExpression(callee, args)
        case .binary(lhs: let lhs, operator: _, rhs: let rhs):
            resolveBinaryExpression(lhs, rhs)
        case .literal, .empty:
            break // do nothing
        case .logical(lhs: let lhs, operator: _, rhs: let rhs):
            resolveLogicalExpression(lhs, rhs)
        case .unary(operator: _, rhs: let expr), .grouping(let expr):
            resolve(expr)
        }
    }

    func resolveUnaryExpression(_ expr: Expression) {
        resolve(expr)
    }

    func resolveLogicalExpression(_ lhs: Expression, _ rhs: Expression) {
        resolve(lhs)
        resolve(rhs)
    }

    func resolveBinaryExpression(_ lhs: Expression, _ rhs: Expression) {
        resolve(lhs)
        resolve(rhs)
    }

    func resolveCallExpression(_ callee: Expression, _ arguments: [Expression]) {
        resolve(callee)
        arguments.forEach(resolve(_:))
    }

    func resolveAssignExpression(_ name: Token, _ value: Expression, _ expr: Expression) {
        resolve(value)
        resolveLocal(expr, name: name)
    }

    func resolveVarExpression(_ name: Token, _ expr: Expression) {
        if !scopes.isEmpty && scopes.last?[name.lexeme] == false {
            Lox.error(token: name, message: "Can't read local variable in its own initiazlier.")
        }
        resolveLocal(expr, name: name)
    }

    func resolveLocal(_ expr: Expression, name: Token) {
        for (idx, scope) in scopes.lazy.enumerated().reversed() where scope[name.lexeme] != nil {
            interpreter.resolve(expr, depth: scope.count - 1 - idx)
            return
        }
    }
}

private extension Resolver {

    func beginScope() {

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
        scopes[scopes.count - 1][token.lexeme] = false
    }

    func define(_ token: Token) {
        if scopes.isEmpty { return }
        // mark the var as resolved
        scopes[scopes.count - 1][token.lexeme] = true
    }
}
