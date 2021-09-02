//
//  File.swift
//  
//
//  Created by user on 29/08/21.
//

import Foundation

final class Instance: CustomStringConvertible {

    private let klass: Class
    private var fields: [String: RuntimeValue] = [:]

    var description: String {
        "\(klass) instance"
    }

    init(klass: Class) {
        self.klass = klass
    }

    func get(_ name: Token) throws -> RuntimeValue {
        if let value = fields[name.lexeme] {
            return value
        }
        if let method = klass.findMethod(name.lexeme) {
            return method.bind(instance: self)
        }
        throw RuntimeError(token: name, message: "Undefined property '\(name.lexeme)'.")
    }

    func set(_ value: RuntimeValue, for name: Token) {
        fields[name.lexeme] = value
    }
}
