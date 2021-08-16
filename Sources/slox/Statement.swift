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
    indirect case `while`(condition: Expr, body: Statement)
}

protocol StatementVisitor {

    associatedtype ReturnValue

    func visitBlockStatement(_ statements: [Statement]) -> ReturnValue
    func visitExpressionStatement(_ expr: Expr) -> ReturnValue
    func visitIfStatement(_ condition: Expr, _ then: Statement, _ else: Statement?) -> ReturnValue
    func visitPrintStatement(_ expr: Expr) -> ReturnValue
    func visitVariableStatement(_ name: Token, _ initializer: Expr) -> ReturnValue
    func visitWhileStatement(_ condition: Expr, _ body: Statement) -> ReturnValue
}
