//
//  File.swift
//  
//
//  Created by user on 8/08/21.
//

import Foundation

struct Interpreter {

    func evaluate(_ expression: Expr) -> RuntimeValue {
        switch expression {
        case .literal(let lit):
            return evaluateLiteral(lit)
        case .grouping(let group):
            return evaluate(group)
        case .unary(operator: let op, rhs: let rhs):
            return evaluateUnary(op, expr: rhs)
        case .binary(lhs: let lhs, operator: let op, rhs: let rhs):
            return evaluateBinary(lhs, operation: op, rhs)
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

    func evaluateUnary(_ operation: Token, expr: Expr) -> RuntimeValue {
        let value = evaluate(expr)

        switch operation.type {
        case .BANG:
            return .bool(!value.isTruthy)
        case .MINUS:
            guard let number = value.number else {
                // TODO: handle this error
                return .none
            }
            return .number(-number)
        // TODO: finish implementing this
        default:
            return .none
        }
    }

    func evaluateBinary(_ lhs: Expr, operation: Token, _ rhs: Expr) -> RuntimeValue {
        let lhs = evaluate(lhs)
        let rhs = evaluate(rhs)

        switch operation.type {

        // MARK: Comparison operations
        case .GREATER:
            return evaluateComparison(lhs, operation: >, rhs)
        case .GREATER_EQUAL:
            return evaluateComparison(lhs, operation: >=, rhs)
        case .LESS:
            return evaluateComparison(lhs, operation: <, rhs)
        case .LESS_EQUAL:
            return evaluateComparison(lhs, operation: <=, rhs)

        // MARK: Equality operations
        case .BANG_EQUAL:
            return .bool(lhs != rhs)
        case .EQUAL_EQUAL:
            return .bool(lhs == rhs)

        // MARK: Arithmetic operations
        case .MINUS:
            return evaluateMath(lhs, operation: -, rhs)
        case .SLASH:
            return evaluateMath(lhs, operation: /, rhs)
        case .STAR:
            return evaluateMath(lhs, operation: *, rhs)
        case .PLUS:
            switch (lhs, rhs) {
            case (.number(let l), .number(let r)):
                return .number(l + r)
            case (.string(let l), .string(let r)):
                return .string(l + r)
            default:
                // TODO: handle this error
                return .none
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
            // TODO: Handle error
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
            // TODO: Handle error
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
