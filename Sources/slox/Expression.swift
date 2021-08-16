//
//  File.swift
//  
//
//  Created by user on 7/08/21.
//

import Foundation

enum Expression {

    indirect case assign(name: Token, value: Expression)
    indirect case binary(lhs: Expression, operator: Token, rhs: Expression)
    indirect case grouping(Expression)
    case literal(Literal?)
    indirect case logical(lhs: Expression, operator: Token, rhs: Expression)
    indirect case unary(operator: Token, rhs: Expression)
    case variable(Token)
    case empty

    static func literal(bool: Bool?) -> Expression {
        if let bool = bool {
            return .literal(.bool(bool))
        }
        return .literal(nil)
    }
}
