//
//  File.swift
//  
//
//  Created by user on 7/08/21.
//

import Foundation

enum Expr {

    indirect case assign(name: Token, value: Expr)
    indirect case binary(lhs: Expr, operator: Token, rhs: Expr)
    indirect case grouping(Expr)
    case literal(Literal?)
    indirect case logical(lhs: Expr, operator: Token, rhs: Expr)
    indirect case unary(operator: Token, rhs: Expr)
    case variable(Token)
    case empty

    static func literal(bool: Bool?) -> Expr {
        if let bool = bool {
            return .literal(.bool(bool))
        }
        return .literal(nil)
    }
}
