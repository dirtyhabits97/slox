//
//  File.swift
//  
//
//  Created by user on 10/08/21.
//

import Foundation

enum Statement {
    case expression(Expr)
    case print(Expr)

    var expr: Expr {
        switch self {
        case .expression(let expr):
            return expr
        case .print(let expr):
            return expr
        }
    }
}
