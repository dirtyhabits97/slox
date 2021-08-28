//
//  File.swift
//  
//
//  Created by user on 28/08/21.
//

import Foundation

final class Resolver {

    private let interpreter: Interpreter
    // The scope is a stack
    private var scopes: [[String: Bool]] = []

    init(interpreter: Interpreter) {
        self.interpreter = interpreter
    }
}

private extension Resolver {

    func resolve(_ statements: [Statement]) {
        for stmt in statements {
            resolve(stmt)
        }
    }

    func resolve(_ statement: Statement) {
        switch statement {
        case .block(let statements):
            resolveBlockStatement(statements)
        case .variable(name: let name, initializer: let initializer):
            resolveVarStatement(name, initializer)
        default:
            break // do nothing
        }
    }

    func resolveBlockStatement(_ stmts: [Statement]) {
        beginScope()
        resolve(stmts)
        endScope()
    }

    func resolveVarStatement(_ name: Token, _ initializer: Expression) {
        declare(name)
        
        define(name)
    }
}

private extension Resolver {

    func beginScope() {

    }

    func endScope() {
        scopes.removeLast()
    }
}

private extension Resolver {

    func declare(_ token: Token) {

    }

    func define(_ token: Token) {

    }
}
