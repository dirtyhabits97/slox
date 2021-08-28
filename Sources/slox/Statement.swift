//
//  File.swift
//  
//
//  Created by user on 10/08/21.
//

import Foundation

enum Statement {

    indirect case block([Statement])
    case expression(Expression)
    indirect case function(name: Token, params: [Token], body: [Statement])
    indirect case `if`(condition: Expression, then: Statement, else: Statement?)
    case print(Expression)
    case `return`(keyword: Token, value: Expression?)
    case variable(name: Token, initializer: Expression)
    indirect case `while`(condition: Expression, body: Statement)
}

protocol StatementVisitor {

    associatedtype ReturnValue

    func visitBlockStatement(_ statements: [Statement]) -> ReturnValue
    func visitExpressionStatement(_ expr: Expression) -> ReturnValue
    func visitIfStatement(_ condition: Expression, _ then: Statement, _ else: Statement?) -> ReturnValue
    func visitPrintStatement(_ expr: Expression) -> ReturnValue
    func visitReturnStatement(_ keyword: Token, _ value: Expression?) -> ReturnValue
    func visitVariableStatement(_ name: Token, _ initializer: Expression) -> ReturnValue
    func visitWhileStatement(_ condition: Expression, _ body: Statement) -> ReturnValue
}
