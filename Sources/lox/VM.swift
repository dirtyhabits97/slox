//
//  File.swift
//  
//
//  Created by user on 20/09/21.
//

import Foundation

private let STACK_MAX = 256

struct VM {

    var chunk: UnsafeMutablePointer<Chunk>?
    // instruction pointer
    var ip: UnsafeMutablePointer<UInt8>?

    var stack = Array(repeating: 0, count: STACK_MAX)
    var stackTop: UnsafeMutablePointer<Value>?
}

// TODO: make this private
internal var vm = VM()

func initVM() {

}

func freeVM() {

}

// MARK: - Run

func run() -> InterpretResult {
    func READ_BYTE() -> UInt8 {
        defer { vm.ip = vm.ip?.advanced(by: 1) }
        return vm.ip!.pointee
    }
    func READ_CONSTANT() -> Value {
        vm.chunk!.pointee.constants.values![Int(READ_BYTE())]
    }

    while true {

#if DEBUG
        disassembleInstruction(
            &vm.chunk!.pointee,
            offset: vm.ip! - vm.chunk!.pointee.code!
        )
#endif

        let instruction = READ_BYTE()
        let opCode = OpCode(rawValue: instruction)
        switch opCode {
        case .OP_CONSTANT:
            let value = READ_CONSTANT()
            printValue(value)
            print("")
        case .OP_RETURN:
            return .INTERPRET_OK
        default:
            print("Unknown \(instruction)")
            return .INTERPRET_RUNTIME_ERROR
        }
    }
}

// MARK: - Interpreter

func interpret(
    _ chunk: UnsafeMutablePointer<Chunk>?
) -> InterpretResult {
    vm.chunk = chunk
    vm.ip = vm.chunk?.pointee.code
    return run()
}

enum InterpretResult {
    case INTERPRET_OK
    case INTERPRET_COMPILE_ERROR
    case INTERPRET_RUNTIME_ERROR
}
