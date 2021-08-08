//
//  File.swift
//  
//
//  Created by user on 8/08/21.
//

import Foundation

struct Interpreter {

    func evaluate(_ expression: Expr) throws -> RuntimeValue {
        switch expression {
        case .literal(let lit):
            return evaluateLiteral(lit)
        case .grouping(let group):
            return try evaluate(group)
        case .unary(operator: let op, rhs: let rhs):
            return try evaluateUnary(op, expr: rhs)
        case .binary(lhs: let lhs, operator: let op, rhs: let rhs):
            return try evaluateBinary(lhs, operation: op, rhs)
        }
    }
}

private extension Interpreter {

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

    func evaluateUnary(_ operation: Token, expr: Expr) throws -> RuntimeValue {
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

    func evaluateBinary(_ lhs: Expr, operation: Token, _ rhs: Expr) throws -> RuntimeValue {
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
