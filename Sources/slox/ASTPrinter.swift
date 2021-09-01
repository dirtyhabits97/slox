//
//  File.swift
//  
//
//  Created by user on 7/08/21.
//

import Foundation

struct ASTPrinter {

    let strategy: Strategy

    init(strategy: Strategy = .prefix) {
        self.strategy = strategy
    }

    func print(_ statements: [Statement]) {
        for stmt in statements {
            Swift.print(description(for: stmt))
        }
    }
}

extension ASTPrinter {

    enum Strategy {
        case prefix
        case infix
        case postfix
    }
}

// MARK: - Statement

private extension ASTPrinter {

    func description(for statement: Statement) -> String {
        do {
            switch statement {
            case .block(let statements):
                return try visitBlockStatement(statements)
            case .class(name: let name, methods: let methods):
                return try visitClassStatement(name, methods)
            case .expression(let expr):
                return try visitExpressionStatement(expr)
            case .function(name: let name, params: let params, body: let body):
                return try visitFunctionStatement(name, params, body)
            case .if(condition: let condition, then: let thenBranch, else: let elseBranch):
                return try visitIfStatement(condition, thenBranch, elseBranch)
            case .print(let expr):
                return try visitPrintStatement(expr)
            case .return(keyword: let keyword, value: let value):
                return try visitReturnStatement(keyword, value)
            case .variable(name: let name, initializer: let initializer):
                return try visitVariableStatement(name, initializer)
            case .while(condition: let condition, body: let body):
                return try visitWhileStatement(condition, body)
            }
        } catch {
            // fail silently for now
            return ""
        }
    }
}

extension ASTPrinter: StatementVisitor {

    typealias ReturnValue = String

    func visitBlockStatement(
        _ statements: [Statement]
    ) throws -> String {
        var str = "(block "

        for stmt in statements {
            str.append(description(for: stmt))
        }

        return str + " )"
    }

    func visitClassStatement(
        _ name: Token,
        _ methods: [Statement]
    ) throws -> String {
        "TODO: set description for class."
    }

    func visitExpressionStatement(
        _ expr: Expression
    ) throws -> String {
        return description(for: expr)
    }

    func visitFunctionStatement(
        _ name: Token,
        _ params: [Token],
        _ body: [Statement]
    ) throws -> String {
        var str = "(fun \(name.lexeme)"

        str.append("(")
        for param in params {
            str.append(" \(param.lexeme)")
        }
        str.append(")")

        for stmt in body {
            str.append(description(for: stmt))
        }

        str.append(")")
        return str
    }

    func visitIfStatement(
        _ condition: Expression,
        _ thenBranch: Statement,
        _ elseBranch: Statement?
    ) throws -> String {
        if let elseBranch = elseBranch {
            return parenthesize("if-else", elements: condition, thenBranch, elseBranch)
        }
        return parenthesize("if", elements: condition, thenBranch)
    }

    func visitPrintStatement(
        _ expr: Expression
    ) throws -> String {
        parenthesize("print", elements: expr)
    }

    func visitReturnStatement(
        _ keyword: Token,
        _ value: Expression
    ) throws -> String {
        parenthesize(keyword.lexeme, elements: value)
    }

    func visitVariableStatement(
        _ name: Token,
        _ initializer: Expression
    ) throws -> String {
        if case .empty = initializer {
            return parenthesize("var", elements: name)
        }
        return parenthesize("var", elements: name, "=", initializer)
    }

    func visitWhileStatement(
        _ condition: Expression,
        _ body: Statement
    ) throws -> String {
        return parenthesize("while", elements: condition, body)
    }
}

// MARK: - Expression description

private extension ASTPrinter {

    func description(for expression: Expression) -> String {
        do {
            switch expression {
            case .assign(name: let name, value: let value):
                return try visitAssignExpression(name, value)
            case .binary(lhs: let lhs, operator: let op, rhs: let rhs):
                return try visitBinaryExpression(lhs, op, rhs)
            case .call(callee: let callee, paren: let paren, arguments: let args):
                return try visitCallExpression(callee, paren, args)
            case .empty:
                return try visitEmptyExpression()
            case .get(object: let obj, name: let name):
                return try visitGetExpression(obj, name)
            case .grouping(let expr):
                return try visitGroupExpression(expr)
            case .literal(let lit):
                return try visitLiteralExpression(lit)
            case .logical(lhs: let lhs, operator: let op, rhs: let rhs):
                return try visitLogicalExpression(lhs, op, rhs)
            case .set(object: let obj, name: let name, value: let value):
                return try visitSetExpression(obj, name, value)
            case .unary(operator: let op, rhs: let rhs):
                return try visitUnaryExpression(op, rhs)
            case .variable(let name):
                return try visitVariableExpression(name)
            }
        } catch {
            // fail silently
            return ""
        }
    }
}

extension ASTPrinter: ExpressionVisitor {

    func visitAssignExpression(
        _ name: Token,
        _ value: Expression
    ) throws -> String {
        parenthesize(name.lexeme, elements: "=", value)
    }

    func visitBinaryExpression(
        _ lhs: Expression,
        _ operation: Token,
        _ rhs: Expression
    ) throws -> String {
        switch strategy {
        case .prefix:
            return parenthesize(operation.lexeme, elements: lhs, rhs)
        case .infix:
            return "(\(description(for: lhs)) \(operation.lexeme) \(description(for: rhs)))"
        case .postfix:
            return "(\(description(for: lhs)) \(description(for: rhs)) \(operation.lexeme))"
        }
    }

    func visitCallExpression(
        _ callee: Expression,
        _ paren: Token,
        _ arguments: [Expression]
    ) throws -> String {
        "TODO: provide a description for call expressions."
    }

    func visitGetExpression(
        _ object: Expression,
        _ name: Token
    ) throws -> String {
        parenthesize("get", elements: object, ".", name)
    }

    func visitGroupExpression(
        _ expr: Expression
    ) throws -> String {
        parenthesize("group", elements: expr)
    }

    func visitLiteralExpression(
        _ literal: Literal
    ) throws -> String {
        literal.description
    }

    func visitLogicalExpression(
        _ lhs: Expression,
        _ operation: Token,
        _ rhs: Expression
    ) throws -> String {
        try visitBinaryExpression(lhs, operation, rhs)
    }

    func visitSetExpression(
        _ object: Expression,
        _ name: Token,
        _ value: Expression
    ) throws -> String {
        parenthesize("set", elements: object, ".", name, "=", value)
    }

    func visitUnaryExpression(
        _ operation: Token,
        _ rhs: Expression
    ) throws -> String {
        parenthesize(operation.lexeme, elements: rhs)
    }

    func visitVariableExpression(
        _ name: Token
    ) throws -> String {
        name.description
    }

    func visitEmptyExpression() throws -> String {
        "nil"
    }
}

// MARK: - Token

private extension ASTPrinter {

    func description(for token: Token) -> String {
        token.lexeme
    }
}

// MARK: - Formatter

private extension ASTPrinter {

    func parenthesize(_ name: String, elements: Any...) -> String {
        var str = "(\(name)"

        for element in elements {
            str.append(" ")

            if let expr = element as? Expression {
                str.append(description(for: expr))
            } else if let stmt = element as? Statement {
                str.append(description(for: stmt))
            } else if let token = element as? Token {
                str.append(description(for: token))
            } else {
                str.append(String(describing: element))
            }

        }
        str.append(")")

        return str
    }
}
