//
//  File.swift
//  
//
//  Created by user on 7/08/21.
//

import Foundation

struct ASTPrinter {

    let strategy: Strategy

    init(strategy: Strategy = .prefix) {
        self.strategy = strategy
    }

    func print(_ expression: Expr) {
        Swift.print(description(for: expression))
    }

    func print(_ statements: [Statement]) {
        for stmt in statements {
            Swift.print(description(for: stmt.expr))
        }
    }

    private func description(for expression: Expr) -> String {
        switch expression {
        case .binary(lhs: let lhs, operator: let op, rhs: let rhs):

            switch strategy {
            case .prefix:
                return prefix(op.lexeme, expressions: lhs, rhs)
            case .infix:
                return "(\(description(for: lhs)) \(op.lexeme) \(description(for: rhs)))"
            case .postfix:
                return "(\(description(for: lhs)) \(description(for: rhs)) \(op.lexeme))"
            }

        case .grouping(let expr):
            return prefix("group", expressions: expr)
        case .literal(let val):
            if let val = val { return String(describing: val) }
            return "nil"
        case .unary(operator: let op, rhs: let rhs):
            return prefix(op.lexeme, expressions: rhs)
        case .variable(let name):
            return name.description
        case .empty:
            return "nil"
        }
    }

    private func prefix(_ name: String, expressions: Expr...) -> String {
        var result = "(\(name)"

        for expr in expressions {
            result.append(" ")
            result.append(description(for: expr))
        }
        result.append(")")

        return result
    }
}

extension ASTPrinter {

    enum Strategy {
        case prefix
        case infix
        case postfix
    }
}
