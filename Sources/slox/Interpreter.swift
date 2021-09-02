//
//  File.swift
//  
//
//  Created by user on 8/08/21.
//

import Foundation

final class Interpreter {

    let globals = Environment()
    private var environment: Environment
    private var locals: [Expression: Int]

    init() {
        globals.define("clock", value: .callable(AnonymousCallable(
            arity: 0,
            call: { _ , _ in .number(Date().timeIntervalSince1970) },
            description: "<native fn>"
        )))
        environment = globals
        locals = [:]
    }

    func interpret(_ statements: [Statement]) {
        do {
            for stmt in statements {
                try execute(stmt)
            }
        } catch let error as RuntimeError {
            Lox.runtimeError(error)
        } catch {
            print("Unhandled error: \(error.localizedDescription).\n\(error)")
        }
    }
}

// MARK: - Statement

internal extension Interpreter {

    @discardableResult
    func execute(_ statement: Statement) throws -> RuntimeValue {
        switch statement {
        case .block(let stmts):
            return try visitBlockStatement(stmts)
        case .class(name: let name, methods: let methods):
            return try visitClassStatement(name, methods)
        case .expression(let expr):
            return try visitExpressionStatement(expr)
        case .function(name: let name, params: let params, body: let body):
            return try visitFunctionStatement(name, params, body)
        case .if(condition: let condition, then: let then, else: let `else`):
            return try visitIfStatement(condition, then, `else`)
        case .print(let expr):
            return try visitPrintStatement(expr)
        case .return(keyword: let keyword, value: let value):
            return try visitReturnStatement(keyword, value)
        case .variable(name: let name, initializer: let initializer):
            return try visitVariableStatement(name, initializer)
        case .while(condition: let condition, body: let body):
            return try visitWhileStatement(condition, body)
        }
    }
}

extension Interpreter: StatementVisitor {

    typealias ReturnValue = RuntimeValue

    func visitBlockStatement(
        _ statements: [Statement]
    ) throws -> RuntimeValue {
        try executeBlockStatement(statements, env: Environment(enclosing: environment))
    }

    func visitClassStatement(
        _ name: Token,
        _ methods: [Statement]
    ) throws -> RuntimeValue {
        environment.define(name.lexeme, value: .none)

        var methodForName: [String: Function] = [:]
        for case let .function(functionName, params, body) in methods {
            let function = Function(
                name: functionName, params: params,
                body: body, closure: environment,
                isInitializer: functionName.lexeme == "init"
            )
            methodForName[functionName.lexeme] = function
        }

        let klass = Class(name: name.lexeme, methods: methodForName)
        try environment.assign(.class(klass), to: name)
        return .none
    }

    func visitExpressionStatement(
        _ expr: Expression
    ) throws -> RuntimeValue {
        try evaluate(expr)
    }

    func visitFunctionStatement(
        _ name: Token,
        _ params: [Token],
        _ body: [Statement]
    ) throws -> ReturnValue {
        let function = Function(
            name: name,
            params: params,
            body: body,
            closure: environment,
            isInitializer: false
        )
        environment.define(name.lexeme, value: .callable(function))
        return .none
    }

    func visitIfStatement(
        _ condition: Expression,
        _ thenBranch: Statement,
        _ elseBranch: Statement?
    ) throws -> RuntimeValue {
        if try evaluate(condition).isTruthy {
            return try execute(thenBranch)
        } else if let elseBranch = elseBranch {
            return try execute(elseBranch)
        }
        return .none
    }

    func visitPrintStatement(
        _ expr: Expression
    ) throws -> RuntimeValue {
        let value = try evaluate(expr)
        print(value)
        return value
    }

    func visitReturnStatement(
        _ keyword: Token,
        _ value: Expression
    ) throws -> RuntimeValue {
        throw Return(value: try evaluate(value))
    }

    func visitVariableStatement(
        _ name: Token,
        _ initializer: Expression
    ) throws -> RuntimeValue {
        let value = try evaluate(initializer)
        environment.define(name.lexeme, value: value)
        return value
    }

    func visitWhileStatement(
        _ condition: Expression,
        _ body: Statement
    ) throws -> RuntimeValue {
        while try evaluate(condition).isTruthy {
            try execute(body)
        }
        return .none
    }
}

// Helper for callables to execute blocks
// given an environment
internal extension Interpreter {

    func executeBlockStatement(
        _ statements: [Statement],
        env environment: Environment
    ) throws -> RuntimeValue {
        let previous = self.environment
        defer { self.environment = previous }

        self.environment = environment
        for stmt in statements {
            try execute(stmt)
        }

        return .none
    }
}

// MARK: - Expression

private extension Interpreter {

    func evaluate(_ expression: Expression) throws -> RuntimeValue {
        switch expression {
        case .assign(name: let name, value: let value):
            return try evaluateAssignmentExpression(name, value, expression)
        case .binary(lhs: let lhs, operator: let op, rhs: let rhs):
            return try visitBinaryExpression(lhs, op, rhs)
        case .call(callee: let callee, paren: let paren, arguments: let args):
            return try visitCallExpression(callee, paren, args)
        case .empty:
            return try visitEmptyExpression()
        case .get(object: let obj, name: let name):
            return try visitGetExpression(obj, name)
        case .grouping(let group):
            return try visitGroupExpression(group)
        case .literal(let lit):
            return try visitLiteralExpression(lit)
        case .logical(lhs: let lhs, operator: let op, rhs: let rhs):
            return try visitLogicalExpression(lhs, op, rhs)
        case .set(object: let obj, name: let name, value: let value):
            return try visitSetExpression(obj, name, value)
        case .this(keyword: let keyword):
            return try evaluateThisExpression(keyword, expression)
        case .unary(operator: let op, rhs: let rhs):
            return try visitUnaryExpression(op, rhs)
        case .variable(let name):
            return try evaluateVariableExpression(name, expression)
        }
    }
}

extension Interpreter: ExpressionVisitor {

    func visitAssignExpression(
        _ name: Token,
        _ value: Expression
    ) throws -> RuntimeValue {
        fatalError("Not implemented. Refer to `evaluateAssignmentExpression(_:_:_:)`.")
    }

    func visitBinaryExpression(
        _ lhs: Expression,
        _ operation: Token,
        _ rhs: Expression
    ) throws -> RuntimeValue {
        try evaluateBinary(lhs, operation, rhs)
    }

    func visitCallExpression(
        _ callee: Expression,
        _ paren: Token,
        _ arguments: [Expression]
    ) throws -> RuntimeValue {
        let callee = try evaluate(callee)

        var args: [RuntimeValue] = []
        for arg in arguments {
            args.append(try evaluate(arg))
        }

        // Validate is a function
        guard let callable = callee.asCallable else {
            throw RuntimeError(token: paren, message: "Can only call functions and classes.")
        }

        // Validate arity
        guard args.count == callable.arity else {
            let message = "Expected \(callable.arity) arguments but got \(args.count)."
            throw RuntimeError(token: paren, message: message)
        }

        return try callable.call(interpreter: self, arguments: args)
    }

    func visitGetExpression(
        _ object: Expression,
        _ name: Token
    ) throws -> RuntimeValue {
        guard case .instance(let instance) = try evaluate(object) else {
            throw RuntimeError(token: name, message: "Only instances have properties.")
        }
        return try instance.get(name)
    }

    func visitGroupExpression(
        _ expr: Expression
    ) throws -> ReturnValue {
        try evaluate(expr)
    }

    func visitLiteralExpression(
        _ literal: Literal
    ) throws -> ReturnValue {
        switch literal {
        case .string(let str):
            return .string(str)
        case .number(let num):
            return .number(num)
        case .bool(let bool):
            return .bool(bool)
        case .none:
            return .none
        }
    }

    func visitLogicalExpression(
        _ lhs: Expression,
        _ operation: Token,
        _ rhs: Expression
    ) throws -> RuntimeValue {
        let lhs = try evaluate(lhs)

        if operation.type == .OR {
            // if the first OR expression is true, don't check the next one
            if lhs.isTruthy { return lhs }
        } else {
            // if the first AND expression is false, don't check the next one
            if !lhs.isTruthy { return lhs }
        }

        return try evaluate(rhs)
    }

    func visitSetExpression(
        _ object: Expression,
        _ name: Token,
        _ value: Expression
    ) throws -> RuntimeValue {
        let object = try evaluate(object)

        guard case .instance(let instance) = object else {
            throw RuntimeError(
                token: name,
                message: "Only instances have fields."
            )
        }
        let value = try evaluate(value)
        instance.set(value, for: name)
        return value
    }

    func visitThisExpression(
        _ keyword: Token
    ) throws -> RuntimeValue {
        fatalError("Not implemented. Refer to `evaluateThisExpression(_:_:)`.")
    }

    func visitUnaryExpression(
        _ operation: Token,
        _ rhs: Expression
    ) throws -> RuntimeValue {
        let value = try evaluate(rhs)
        switch operation.type {
        case .BANG:
            return .bool(!value.isTruthy)
        case .MINUS:
            guard let number = value.number else {
                throw RuntimeError(token: operation, message: "Operand must be a number.")
            }
            return .number(-number)
        default:
            return .none
        }
    }

    func visitVariableExpression(
        _ name: Token
    ) throws -> RuntimeValue {
        fatalError("Not implemented. Refer to `evaluateVariableExpression(_:_:)`.")
    }

    func visitEmptyExpression() throws -> RuntimeValue {
        .none
    }
}

private extension Interpreter {

    func evaluateAssignmentExpression(
        _ name: Token,
        _ value: Expression,
        _ expr: Expression
    ) throws -> RuntimeValue {
        let value = try evaluate(value)
        if let distance = locals[expr] {
            environment.assign(name, at: distance, value)
        } else {
            try globals.assign(value, to: name)
        }
        return value
    }

    func evaluateBinary(
        _ lhs: Expression,
        _ operation: Token,
        _ rhs: Expression
    ) throws -> RuntimeValue {
        let lhs = try evaluate(lhs)
        let rhs = try evaluate(rhs)

        switch operation.type {

        // MARK: Comparison operations
        case .GREATER:
            try checkNumberOperands(operation, lhs, rhs)
            return evaluateComparison(lhs, >, rhs)
        case .GREATER_EQUAL:
            try checkNumberOperands(operation, lhs, rhs)
            return evaluateComparison(lhs, >=, rhs)
        case .LESS:
            try checkNumberOperands(operation, lhs, rhs)
            return evaluateComparison(lhs, <, rhs)
        case .LESS_EQUAL:
            try checkNumberOperands(operation, lhs, rhs)
            return evaluateComparison(lhs, <=, rhs)

        // MARK: Equality operations
        case .BANG_EQUAL:
            return try evaluateEquality(operation, lhs, rhs)
        case .EQUAL_EQUAL:
            return try evaluateEquality(operation, lhs, rhs)

        // MARK: Arithmetic operations
        case .MINUS:
            try checkNumberOperands(operation, lhs, rhs)
            return evaluateMath(lhs, -, rhs)
        case .SLASH:
            try checkNumberOperands(operation, lhs, rhs)
            return evaluateMath(lhs, /, rhs)
        case .STAR:
            try checkNumberOperands(operation, lhs, rhs)
            return evaluateMath(lhs, *, rhs)
        case .PLUS:
            switch (lhs, rhs) {
            case (.number(let l), .number(let r)):
                return .number(l + r)
            case (.string(let l), .string(let r)):
                return .string(l + r)

            // Chapter 7, assignment 2:
            // Many languages define + such that if either operand is
            // a string, the other is converted to a string and the
            // results are then concatenated
            case (.string(let l), .number(let r)):
                return .string(l + String(r))
            case (.number(let l), .string(let r)):
                return .string(String(l) + r)

            default:
                throw RuntimeError(
                    token: operation,
                    message: "Operands must be two numbers or two strings."
                )
            }

        default:
            return .none
        }
    }

    func evaluateThisExpression(
        _ keyword: Token,
        _ expr: Expression
    ) throws -> RuntimeValue {
        try lookUpVariable(keyword, expr)
    }

    func evaluateVariableExpression(
        _ name: Token,
        _ expr: Expression
    ) throws -> RuntimeValue {
        try lookUpVariable(name, expr)
    }
}

private extension Interpreter {

    func evaluateMath(
        _ lhs: RuntimeValue,
        _ operation: (Double, Double) -> Double,
        _ rhs: RuntimeValue
    ) -> RuntimeValue {
        guard let l = lhs.number, let r = rhs.number else {
            return .none
        }
        return .number(operation(l, r))
    }

    func evaluateComparison(
        _ lhs: RuntimeValue,
        _ operation: (Double, Double) -> Bool,
        _ rhs: RuntimeValue
    ) -> RuntimeValue {
        guard let l = lhs.number, let r = rhs.number else {
            return .none
        }
        return .bool(operation(l, r))
    }

    func evaluateEquality(
        _ operation: Token,
        _ lhs: RuntimeValue,
        _ rhs: RuntimeValue
    ) throws -> RuntimeValue {
        let bool: Bool
        switch (lhs, rhs) {
        case (.number(let l), .number(let r)):
            bool = l == r
        case (.string(let l), .string(let r)):
            bool = l == r
        case (.bool(let l), .bool(let r)):
            bool = l == r
        case (.none, .none):
            bool = true
        default:
            throw RuntimeError(token: operation, message: "Can't compare \(lhs) and \(rhs)")
        }

        if operation.type == .BANG_EQUAL {
            return .bool(!bool)
        }
        return .bool(bool)
    }
}

private extension Interpreter {

    func checkNumberOperand(
        _ operation: Token,
        operand: RuntimeValue
    ) throws {
        guard case .number(_) = operand else {
            throw RuntimeError(token: operation, message: "Operand must be a number.")
        }
    }

    func checkNumberOperands(
        _ operation: Token,
        _ lhs: RuntimeValue,
        _ rhs: RuntimeValue
    ) throws {
        switch (lhs, rhs) {
        case (.number, .number):
            break
        default:
            throw RuntimeError(token: operation, message: "Operands must be numbers.")
        }
    }
}

// MARK: - Variable resolution

extension Interpreter {

    func resolve(_ expr: Expression, depth: Int) {
        locals[expr] = depth
    }
}

private extension Interpreter {

    func lookUpVariable(_ name: Token, _ expr: Expression) throws -> RuntimeValue {
        if let distance = locals[expr],
           // the distance in the environment hierarchy
           let value = environment.get(name.lexeme, distance: distance) {
            return value
        }
        return try globals.get(name)
    }
}
