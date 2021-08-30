//
//  File.swift
//  
//
//  Created by user on 10/08/21.
//

import Foundation

enum Statement {

    indirect case block([Statement])
    case `class`(name: Token, methods: [Statement])
    case expression(Expression)
    indirect case function(name: Token, params: [Token], body: [Statement])
    indirect case `if`(condition: Expression, then: Statement, else: Statement?)
    case print(Expression)
    case `return`(keyword: Token, value: Expression)
    case variable(name: Token, initializer: Expression)
    indirect case `while`(condition: Expression, body: Statement)
}

protocol StatementVisitor {

    associatedtype ReturnValue

    func visitBlockStatement(_ statements: [Statement]) throws -> ReturnValue
    func visitClassStatement(_ name: Token, _ methods: [Statement]) throws -> ReturnValue
    func visitExpressionStatement(_ expr: Expression) throws -> ReturnValue
    func visitFunctionStatement(_ name: Token, _ params: [Token], _ body: [Statement]) throws -> ReturnValue
    func visitIfStatement(_ condition: Expression, _ thenBranch: Statement, _ elseBranch: Statement?) throws -> ReturnValue
    func visitPrintStatement(_ expr: Expression) throws -> ReturnValue
    func visitReturnStatement(_ keyword: Token, _ value: Expression) throws -> ReturnValue
    func visitVariableStatement(_ name: Token, _ initializer: Expression) throws -> ReturnValue
    func visitWhileStatement(_ condition: Expression, _ body: Statement) throws -> ReturnValue
}
