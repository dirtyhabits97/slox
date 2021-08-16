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

// MARK: - Statement description

extension ASTPrinter: StatementVisitor {

    func description(for statement: Statement) -> String {
        switch statement {
        case .block(let statements):
            return visitBlockStatement(statements)
        case .expression(let expr):
            return visitExpressionStatement(expr)
        case .if(condition: let condition, then: let thenBranch, else: let elseBranch):
            return visitIfStatement(condition, thenBranch, elseBranch)
        case .print(let expr):
            return visitPrintStatement(expr)
        case .variable(name: let name, initializer: let initializer):
            return visitVariableStatement(name, initializer)
        case .while(condition: let condition, body: let body):
            return visitWhileStatement(condition, body)
        }
    }

    func visitBlockStatement(_ statements: [Statement]) -> String {
        var str = "(block "

        for stmt in statements {
            str.append(description(for: stmt))
        }

        return str + " )"
    }

    func visitExpressionStatement(_ expr: Expression) -> String {
        return description(for: expr)
    }

    func visitIfStatement(_ condition: Expression, _ thenBranch: Statement, _ elseBranch: Statement?) -> String {
        if let elseBranch = elseBranch {
            return parenthesize("if-else", elements: condition, thenBranch, elseBranch)
        }
        return parenthesize("if", elements: condition, thenBranch)
    }

    func visitPrintStatement(_ expr: Expression) -> String {
        return parenthesize("print", elements: expr)
    }

    func visitVariableStatement(_ name: Token, _ initializer: Expression) -> String {
        if case .empty = initializer {
            return parenthesize("var", elements: name)
        }
        return parenthesize("var", elements: name, "=", initializer)
    }

    func visitWhileStatement(_ condition: Expression, _ body: Statement) -> String {
        return parenthesize("while", elements: condition, body)
    }
}

// MARK: - Expression description

private extension ASTPrinter {

    func description(for expression: Expression) -> String {
        switch expression {
        case .binary(lhs: let lhs, operator: let op, rhs: let rhs),
             .logical(let lhs, let op, let rhs):

            switch strategy {
            case .prefix:
                return parenthesize(op.lexeme, elements: lhs, rhs)
            case .infix:
                return "(\(description(for: lhs)) \(op.lexeme) \(description(for: rhs)))"
            case .postfix:
                return "(\(description(for: lhs)) \(description(for: rhs)) \(op.lexeme))"
            }

        case .grouping(let expr):
            return parenthesize("group", elements: expr)
        case .literal(let val):
            if let val = val { return String(describing: val) }
            return "nil"
        case .unary(operator: let op, rhs: let rhs):
            return parenthesize(op.lexeme, elements: rhs)
        case .variable(let name):
            return name.description
        case .empty:
            return "nil"
        case .assign(name: let name, value: let value):
            return parenthesize(name.lexeme, elements: "=", value)
        }
    }
}

// MARK: - Token description

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
