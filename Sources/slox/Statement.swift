//
//  File.swift
//  
//
//  Created by user on 10/08/21.
//

import Foundation

enum Statement {

    indirect case block([Statement])
    case expression(Expr)
    indirect case `if`(condition: Expr, then: Statement, else: Statement?)
    case print(Expr)
    case variable(name: Token, initializer: Expr)
}
