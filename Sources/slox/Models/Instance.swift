//
//  File.swift
//  
//
//  Created by user on 29/08/21.
//

import Foundation

struct Instance: CustomStringConvertible {

    private let klass: Class
    private var fields: [String: RuntimeValue] = [:]

    var description: String {
        "\(klass) instance "
    }

    init(klass: Class) {
        self.klass = klass
    }

    func get(_ name: Token) throws -> RuntimeValue {
        guard let value = fields[name.lexeme] else {
            throw RuntimeError(token: name, message: "Undefined property '\(name.lexeme)'.")
        }
        return value
    }
}
