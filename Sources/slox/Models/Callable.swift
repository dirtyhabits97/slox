//
//  File.swift
//  
//
//  Created by user on 27/08/21.
//

import Foundation

protocol Callable: CustomStringConvertible {

    /// Number of arguments a function or operation expects.
    var arity: Int { get }
    func call(
        interpreter: Interpreter,
        arguments: [RuntimeValue]
    ) throws -> RuntimeValue
}

struct AnonymousCallable: Callable {

    let arity: Int
    let call: (Interpreter, [RuntimeValue]) throws -> RuntimeValue
    let description: String

    func call(interpreter: Interpreter, arguments: [RuntimeValue]) throws -> RuntimeValue {
        try call(interpreter, arguments)
    }
}

struct Function: Callable {

    let name: Token
    let params: [Token]
    let body: [Statement]
    // this helps with nested closures / functions
    let environment: Environment

    var arity: Int { params.count }

    var description: String {
        "<fn \(name.lexeme)>"
    }

    func call(
        interpreter: Interpreter,
        arguments: [RuntimeValue]
    ) throws -> RuntimeValue {
        let environment = Environment(enclosing: environment)
        for (param, arg) in zip(params, arguments) {
            environment.define(param.lexeme, value: arg)
        }
        do {
            // TODO: consider ignoring this value and always return .none
            return try interpreter.executeBlockStatement(body, env: environment)
        } catch let returnValue as Return {
            return returnValue.value
        }
    }

    func bind(instance: Instance) -> RuntimeValue {
        let environment = Environment(enclosing: environment)
        environment.define("this", value: .instance(instance))
        return .callable(Function(
            name: name, params: params,
            body: body, environment: environment
        ))
    }
}
