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

    // Naive approach for now
    var stack = [Value?](repeating: nil, count: STACK_MAX)
    var stackTop = 0
}

private var vm = VM()

private func resetStack() {
    vm.stackTop = 0
}

private func push(_ value: Value) {
    vm.stack[vm.stackTop] = value
    vm.stackTop += 1
}

private func pop() -> Value {
    vm.stackTop -= 1
    return vm.stack[vm.stackTop]!
}

func initVM() {
    resetStack()
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
    func BINARY_OP(_ op: (Value, Value) -> Value) {
        let rhs = pop()
        let lhs = pop()
        push(op(lhs, rhs))
    }

    while true {

#if DEBUG
        print("          ", terminator: "")
        for slot in 0..<vm.stackTop {
            print("[ ", terminator: "")
            printValue(vm.stack[slot]!)
            print(" ]", terminator: "")
        }
        print("")

        disassembleInstruction(
            &vm.chunk!.pointee,
            offset: vm.ip! - vm.chunk!.pointee.code!
        )
#endif

        let instruction = READ_BYTE()
        let opCode = OpCode(rawValue: instruction)
        switch opCode {
        case .OP_CONSTANT:
            push(READ_CONSTANT())
        case .OP_NEGATE:
            push(-pop())

        case .OP_ADD:
            BINARY_OP(+)
        case .OP_SUBSTRACT:
            BINARY_OP(-)
        case .OP_MULTIPLY:
            BINARY_OP(*)
        case .OP_DIVIDE:
            BINARY_OP(/)

        case .OP_RETURN:
            printValue(pop())
            print("")
            return .INTERPRET_OK
        case .none:
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
