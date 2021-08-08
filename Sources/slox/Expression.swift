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
    case literal(Literal?)
    case unary(operator: Token, rhs: Expr)
}
