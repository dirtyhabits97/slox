//
//  File.swift
//  
//
//  Created by user on 7/08/21.
//

import Foundation

indirect enum Expr {

    case binary(lhs: Expr, operator: Token, rhs: Expr)
    case grouping(Expr)
    case literal(Any?)
    case unary(operator: Token, rhs: Expr)
}

extension Expr: CustomStringConvertible {
    var description: String {
        switch self {
        case .binary(lhs: let lhs, operator: let op, rhs: let rhs):
            return parenthesize(op.lexeme, expressions: lhs, rhs)
        case .grouping(let expr):
            return parenthesize("group", expressions: expr)
        case .literal(let val):
            if let val = val { return String(describing: val) }
            return "nil"
        case .unary(operator: let op, rhs: let rhs):
            return parenthesize(op.lexeme, expressions: rhs)
        }
    }

    private func parenthesize(_ name: String, expressions: Expr...) -> String {
        var result = "(\(name)"

        for expr in expressions {
            result.append(" ")
            result.append(expr.description)
        }
        result.append(")")

        return result
    }
}
