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
    indirect case grouping(Expression)
    case literal(Literal)
    indirect case logical(lhs: Expression, operator: Token, rhs: Expression)
    indirect case unary(operator: Token, rhs: Expression)
    case variable(Token)
    case empty
}

protocol ExpressionVisitor {

    associatedtype ReturnValue

    func visitAssignExpression(_ name: Token, _ value: Expression) throws -> ReturnValue
    func visitBinaryExpression(_ lhs: Expression, _ operation: Token, _ rhs: Expression) throws -> ReturnValue
    func visitCallExpression(_ callee: Expression, _ paren: Token, _ arguments: [Expression]) throws -> ReturnValue
    func visitEmptyExpression() throws -> ReturnValue
    func visitGroupExpression(_ expr: Expression) throws -> ReturnValue
    func visitLiteralExpression(_ literal: Literal) throws -> ReturnValue
    func visitLogicalExpression(_ lhs: Expression, _ operation: Token, _ rhs: Expression) throws -> ReturnValue
    func visitUnaryExpression(_ operation: Token, _ rhs: Expression) throws -> ReturnValue
    func visitVariableExpression(_ name: Token) throws -> ReturnValue
}
