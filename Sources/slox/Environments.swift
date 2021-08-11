//
//  File.swift
//  
//
//  Created by user on 11/08/21.
//

import Foundation

final class Environment {

    private var values: [String: RuntimeValue] = [:]

    func define(_ value: RuntimeValue, for name: String) {
        values[name] = value
    }

    func get(_ name: Token) throws -> RuntimeValue {
        if let value = values[name.lexeme] {
            return value
        }
        throw RuntimeError(token: name, message: "Undefined variable '\(name.lexeme)'.")
    }
}
