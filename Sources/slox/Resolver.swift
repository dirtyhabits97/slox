//
//  File.swift
//  
//
//  Created by user on 28/08/21.
//

import Foundation

final class Resolver {

    private let interpreter: Interpreter
    private var currentClass = ClassType.none
    private var currentFunction = FunctionType.none
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
            case .class(let name, let superclass, let methods):
                try visitClassStatement(name, superclass, methods)
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

    func resolveFunction(
        _ name: Token,
        _ params: [Token],
        _ body: [Statement],
        _ type: FunctionType
    ) {
        let enclosingFunction = currentFunction
        currentFunction = type
        defer { currentFunction = enclosingFunction }

        beginScope()
        for param in params {
            declare(param)
            define(param)
        }
        resolve(body)
        endScope()
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
        _ superclass: Expression,
        _ methods: [Statement]
    ) throws {
        let enclosingClass = currentClass
        currentClass = .class
        defer { currentClass = enclosingClass }

        declare(name)
        define(name)

        // validate superclass
        if
            case .variable(let varName) = superclass,
            name.lexeme == varName.lexeme
        {
            Lox.error(token: varName, message: "A class can't inherit from itself.")
        }
        resolve(superclass)

        // declare "super"
        if case .variable = superclass {
            beginScope()
            scopes[scopes.count - 1]["super"] = true
        }

        // declare "this"
        beginScope()
        scopes[scopes.count - 1]["this"] = true

        for case let .function(functionName, params, body) in methods {
            let type: FunctionType = functionName.lexeme == "init" ? .initializer : .method
            resolveFunction(functionName, params, body, type)
        }
        endScope()
        if case .variable = superclass { endScope() }
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
        resolveFunction(name, params, body, .function)
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
        if value != .empty && currentFunction == .initializer {
            Lox.error(token: keyword, message: "Can't return a value from an initializer.")
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
            case .set(object: let obj, name: let name, value: let value):
                try visitSetExpression(obj, name, value)
            case .super(keyword: let keyword, method: let method):
                resolveSuperExpression(keyword, method, expression)
            case .this(keyword: let keyword):
                resolveThisExpression(keyword, expression)
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

    func resolveSuperExpression(
        _ keyword: Token,
        _ method: Token,
        _ expr: Expression
    ) {
        resolveLocal(expr, name: keyword)
    }

    func resolveThisExpression(
        _ keyword: Token,
        _ expr: Expression
    ) {
        if currentClass == .none {
            Lox.error(
                token: keyword,
                message: "Can't use 'this' outside of a class."
            )
            return
        }
        resolveLocal(expr, name: keyword)
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

    func visitSetExpression(
        _ object: Expression,
        _ name: Token,
        _ value: Expression
    ) throws -> () {
        resolve(value)
        resolve(object)
    }

    func visitSuperExpression(
        _ keyword: Token,
        _ method: Token
    ) throws -> () {
        fatalError("Not implemented. Refer to `resolveSuperExpression(_:_:_:)`.")
    }

    func visitThisExpression(
        _ keyword: Token
    ) throws -> () {
        fatalError("Not implemented. Refer to `resolveThisExpression(_:_:)`.")
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
        for (i, scope) in zip(0 ... scopes.count, scopes).reversed() {
            if scope[name.lexeme] != nil {
                let numOfScopes = scopes.count - 1 - i
                interpreter.resolve(expr, depth: numOfScopes)
                return
            }
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

    enum FunctionType {
        case none
        case function
        case initializer
        case method
    }

    enum ClassType {
        case none
        case `class`
    }
}
