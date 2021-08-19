//
//  File.swift
//  
//
//  Created by user on 8/08/21.
//

import Foundation

final class Interpreter {

    private var environment = Environment()

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

private extension Interpreter {

    @discardableResult
    func execute(_ statement: Statement) throws -> RuntimeValue {
        switch statement {
        case .expression(let expr):
            return try evaluate(expr)
        case .print(let expr):
            let value = try evaluate(expr)
            print(value)
            return value
        case .variable(name: let name, initializer: let initializer):
            return try executeVarStatement(name, initializer)
        case .block(let statements):
            return try executeBlockStatement(
                statements,
                env: Environment(enclosing: environment)
            )
        case .if(condition: let condition, then: let then, else: let `else`):
            return try executeIfStatement(condition, then, `else`)
        case .while(condition: let condition, body: let body):
            return try executeWhileStatement(condition, body)
        }
    }

    func executeWhileStatement(
        _ condition: Expression,
        _ body: Statement
    ) throws -> RuntimeValue {
        while try evaluate(condition).isTruthy {
            try execute(body)
        }
        return .none
    }

    func executeIfStatement(
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

    func executeBlockStatement(
        _ statements: [Statement],
        env environment: Environment
    ) throws -> RuntimeValue {
        let previous = self.environment
        defer { self.environment = previous }
        
        do {
            self.environment = environment

            for stmt in statements {
                try execute(stmt)
            }
        }
        // TODO: this method shouldn't return
        return .none
    }

    func executeVarStatement(_ name: Token, _ initializer: Expression) throws -> RuntimeValue {
        let value = try evaluate(initializer)
        environment.define(value, for: name.lexeme)
        return value
    }
}

private extension Interpreter {

    func evaluate(_ expression: Expression) throws -> RuntimeValue {
        switch expression {
        case .literal(let lit):
            return evaluateLiteral(lit)
        case .grouping(let group):
            return try evaluate(group)
        case .unary(operator: let op, rhs: let rhs):
            return try evaluateUnary(op, expr: rhs)
        case .binary(lhs: let lhs, operator: let op, rhs: let rhs):
            return try evaluateBinary(lhs, operation: op, rhs)
        case .empty:
            return .none
        case .variable(let name):
            return try environment.get(name)
        case .assign(name: let name, value: let value):
            return try evaluateAssignment(name, value)
        case .logical(lhs: let lhs, operator: let op, rhs: let rhs):
            return try evaluateLogic(lhs, op, rhs)
        case .call(callee: let callee, paren: let paren, arguments: let args):

        }
    }

    func evaluateLogic(
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

    func evaluateAssignment(_ name: Token, _ value: Expression) throws -> RuntimeValue {
        let value = try evaluate(value)
        try environment.assign(value, to: name)
        return value
    }

    func evaluateLiteral(_ literal: Literal?) -> RuntimeValue {
        guard let literal = literal else { return .none }

        switch literal {
        case .string(let str):
            return .string(str)
        case .number(let num):
            return .number(num)
        case .bool(let bool):
            return .bool(bool)
        }
    }

    func evaluateUnary(_ operation: Token, expr: Expression) throws -> RuntimeValue {
        let value = try evaluate(expr)

        switch operation.type {
        case .BANG:
            return .bool(!value.isTruthy)
        case .MINUS:
            guard let number = value.number else {
                throw RuntimeError(token: operation, message: "Operand must be a number.")
            }
            return .number(-number)
        // TODO: finish implementing this
        default:
            return .none
        }
    }

    func evaluateBinary(_ lhs: Expression, operation: Token, _ rhs: Expression) throws -> RuntimeValue {
        let lhs = try evaluate(lhs)
        let rhs = try evaluate(rhs)

        switch operation.type {

        // MARK: Comparison operations
        case .GREATER:
            try checkNumberOperands(operation, lhs, rhs)
            return evaluateComparison(lhs, operation: >, rhs)
        case .GREATER_EQUAL:
            try checkNumberOperands(operation, lhs, rhs)
            return evaluateComparison(lhs, operation: >=, rhs)
        case .LESS:
            try checkNumberOperands(operation, lhs, rhs)
            return evaluateComparison(lhs, operation: <, rhs)
        case .LESS_EQUAL:
            try checkNumberOperands(operation, lhs, rhs)
            return evaluateComparison(lhs, operation: <=, rhs)

        // MARK: Equality operations
        case .BANG_EQUAL:
            return .bool(lhs != rhs)
        case .EQUAL_EQUAL:
            return .bool(lhs == rhs)

        // MARK: Arithmetic operations
        case .MINUS:
            try checkNumberOperands(operation, lhs, rhs)
            return evaluateMath(lhs, operation: -, rhs)
        case .SLASH:
            try checkNumberOperands(operation, lhs, rhs)
            return evaluateMath(lhs, operation: /, rhs)
        case .STAR:
            try checkNumberOperands(operation, lhs, rhs)
            return evaluateMath(lhs, operation: *, rhs)
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

    func evaluateMath(
        _ lhs: RuntimeValue,
        operation: (Double, Double) -> Double,
        _ rhs: RuntimeValue
    ) -> RuntimeValue {
        guard let l = lhs.number, let r = rhs.number else {
            return .none
        }
        return .number(operation(l, r))
    }

    func evaluateComparison(
        _ lhs: RuntimeValue,
        operation: (Double, Double) -> Bool,
        _ rhs: RuntimeValue
    ) -> RuntimeValue {
        guard let l = lhs.number, let r = rhs.number else {
            return .none
        }
        return .bool(operation(l, r))
    }
}

enum RuntimeValue: Equatable {

    case number(Double)
    case string(String)
    case bool(Bool)
    case none

    var number: Double? {
        switch self {
        case .number(let num):
            return num
        default:
            return nil
        }
    }

    // What is truth?
    // https://craftinginterpreters.com/evaluating-expressions.html#truthiness-and-falsiness
    var isTruthy: Bool {
        // For now, follow ruby's rule
        switch self {
        case .none:
            return false
        case .bool(let bool):
            return bool
        default:
            return true
        }
    }
}

extension RuntimeValue: CustomStringConvertible {

    var description: String {
        switch self {
        case .none:
            return "nil"
        case .number(let num):
            return String(num)
        case .string(let str):
            return "\"\(str)\""
        case .bool(let bool):
            return String(bool)
        }
    }
}

private extension Interpreter {

    func checkNumberOperand(_ operation: Token, operand: RuntimeValue) throws {
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

struct RuntimeError: Error {

    let token: Token
    let message: String
}
