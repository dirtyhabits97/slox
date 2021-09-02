//
//  File.swift
//  
//
//  Created by user on 11/08/21.
//

import Foundation

final class Environment {

    private var values: [String: RuntimeValue] = [:]
    private let enclosing: Environment?

    init(enclosing: Environment? = nil) {
        self.enclosing = enclosing
    }

    func define(_ name: String, value: RuntimeValue) {
        values[name] = value
    }

    func get(_ name: Token) throws -> RuntimeValue {
        if let value = values[name.lexeme] {
            return value
        }

        if let enclosing = self.enclosing {
            return try enclosing.get(name)
        }

        throw RuntimeError(token: name, message: "Undefined variable '\(name.lexeme)'.")
    }

    func assign(_ value: RuntimeValue, to name: Token) throws {
        if values[name.lexeme] != nil {
            values[name.lexeme] = value
            return
        }

        if let enclosing = self.enclosing {
            try enclosing.assign(value, to: name)
            return
        }

        throw RuntimeError(token: name, message: "Undefined variable '\(name.lexeme)'.")
    }
}

// MARK: - Variable resolution

extension Environment {

    func get(
        _ name: String,
        distance: Int
    ) -> RuntimeValue? {
        ancestor(at: distance).values[name]
    }

    func assign(
        _ name: Token,
        at distance: Int,
        _ value: RuntimeValue
    ) {
        ancestor(at: distance).values[name.lexeme] = value
    }

    private func ancestor(
        at distance: Int
    ) -> Environment {
        var environment: Environment = self
        for _ in 0..<distance {
            environment = environment.enclosing!
        }
        return environment
    }
}
