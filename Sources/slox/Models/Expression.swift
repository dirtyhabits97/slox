//
//  File.swift
//  
//
//  Created by user on 7/08/21.
//

import Foundation

enum Expression: Hashable {

    indirect case assign(name: Token, value: Expression)
    indirect case binary(lhs: Expression, operator: Token, rhs: Expression)
    indirect case call(callee: Expression, paren: Token, arguments: [Expression])
    case empty
    indirect case get(object: Expression, name: Token)
    indirect case grouping(Expression)
    case literal(Literal)
    indirect case logical(lhs: Expression, operator: Token, rhs: Expression)
    indirect case set(object: Expression, name: Token, value: Expression)
    indirect case unary(operator: Token, rhs: Expression)
    case variable(Token)
}

protocol ExpressionVisitor {

    associatedtype ReturnValue

    func visitAssignExpression(_ name: Token, _ value: Expression) throws -> ReturnValue
    func visitBinaryExpression(_ lhs: Expression, _ operation: Token, _ rhs: Expression) throws -> ReturnValue
    func visitCallExpression(_ callee: Expression, _ paren: Token, _ arguments: [Expression]) throws -> ReturnValue
    func visitEmptyExpression() throws -> ReturnValue
    func visitGetExpression(_ object: Expression, _ name: Token) throws -> ReturnValue
    func visitGroupExpression(_ expr: Expression) throws -> ReturnValue
    func visitLiteralExpression(_ literal: Literal) throws -> ReturnValue
    func visitLogicalExpression(_ lhs: Expression, _ operation: Token, _ rhs: Expression) throws -> ReturnValue
    func visitSetExpression(_ object: Expression, _ name: Token, _ value: Expression) throws -> ReturnValue
    func visitUnaryExpression(_ operation: Token, _ rhs: Expression) throws -> ReturnValue
    func visitVariableExpression(_ name: Token) throws -> ReturnValue
}
