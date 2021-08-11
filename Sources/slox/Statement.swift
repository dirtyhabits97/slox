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
    case print(Expr)
    case variable(name: Token, initializer: Expr)
}
