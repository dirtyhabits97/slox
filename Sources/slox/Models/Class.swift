//
//  File.swift
//  
//
//  Created by user on 29/08/21.
//

import Foundation

final class Class: CustomStringConvertible {

    let name: String
    let superclass: Class?
    private let methods: [String: Function]

    var description: String { name }

    init(
        name: String,
        superclass: Class?,
        methods: [String: Function]
    ) {
        self.name = name
        self.superclass = superclass
        self.methods = methods
    }

    func findMethod(_ name: String) -> Function? {
        if let method = methods[name] {
            return method
        }
        return superclass?.findMethod(name)
    }
}

extension Class: Callable {

    var arity: Int {
        if let initializer = findMethod("init") {
            return initializer.arity
        }
        return 0
    }

    func call(
        interpreter: Interpreter,
        arguments: [RuntimeValue]
    ) throws -> RuntimeValue {
        let instance = Instance(klass: self)
        if let initializer = findMethod("init") {
            _ = try initializer.bind(instance: instance)
                .asCallable?
                .call(interpreter: interpreter, arguments: arguments)
        }
        return .instance(instance)
    }
}
