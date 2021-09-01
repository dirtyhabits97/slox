//
//  File.swift
//  
//
//  Created by user on 29/08/21.
//

import Foundation

struct Class: CustomStringConvertible {

    let name: String
    let methods: [String: Function]
    var description: String { name }
}

extension Class: Callable {

    var arity: Int { 0 }

    func call(
        interpreter: Interpreter,
        arguments: [RuntimeValue]
    ) throws -> RuntimeValue {
        .instance(Instance(klass: self))
    }
}
