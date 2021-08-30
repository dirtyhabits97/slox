//
//  File.swift
//  
//
//  Created by user on 27/08/21.
//

import Foundation

enum RuntimeValue {

    case number(Double)
    case string(String)
    case bool(Bool)
    case none
    case callable(Callable)
    case `class`(Class)

    var number: Double? {
        switch self {
        case .number(let num):
            return num
        default:
            return nil
        }
    }

    // What is truth?
    // https://craftinginterpreters.com/evaluating-expressions.html#truthiness-and-falsiness
    var isTruthy: Bool {
        // For now, follow ruby's rule
        switch self {
        case .none:
            return false
        case .bool(let bool):
            return bool
        default:
            return true
        }
    }
}

extension RuntimeValue: CustomStringConvertible {

    var description: String {
        switch self {
        case .none:
            return "nil"
        case .number(let num):
            return String(num)
        case .string(let str):
            return "\"\(str)\""
        case .bool(let bool):
            return String(bool)
        case .callable(let call):
            return call.description
        case .class(let klass):
            return klass.description
        }
    }
}

struct RuntimeError: Error {

    let token: Token
    let message: String
}
