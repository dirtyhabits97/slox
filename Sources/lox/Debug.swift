//
//  File.swift
//  
//
//  Created by user on 19/09/21.
//

import Foundation

func disassembleChunk(_ chunk: inout Chunk, name: String) {
    print("== \(name) ==")

    var offset = 0
    while offset < chunk.count {
        offset = disassembleInstruction(&chunk, offset: offset)
    }
}

@discardableResult
func disassembleInstruction(_ chunk: inout Chunk, offset: Int) -> Int {
    print(String(format: "%04d ", offset), terminator: "")
    if offset > 0 && chunk.lines?[offset] == chunk.lines?[offset - 1] {
        print("   | ", terminator: "")
    } else {
        print(String(format: "%4d ", chunk.lines![offset]), terminator: "")
    }
    
    let instruction = chunk.code?[offset]
    let opCode = instruction.flatMap(OpCode.init)
    switch opCode {
    case .OP_CONSTANT:
        return constantInstruction("OP_CONSTANT", chunk, offset)

    case .OP_ADD:
        return simpleInstruction("OP_ADD", offset)
    case .OP_SUBSTRACT:
        return simpleInstruction("OP_SUBSTRACT", offset)
    case .OP_MULTIPLY:
        return simpleInstruction("OP_MULTIPLY", offset)
    case .OP_DIVIDE:
        return simpleInstruction("OP_DIVIDE", offset)

    case .OP_NEGATE:
        return simpleInstruction("OP_NEGATE", offset)
    case .OP_RETURN:
        return simpleInstruction("OP_RETURN", offset)
    case .none:
        print("Unknown opcode \(String(describing: instruction))")
        return offset + 1
    }
}

private func constantInstruction(
    _ name: String,
    _ chunk: Chunk,
    _ offset: Int
) -> Int {
    let constant = chunk.code![offset + 1]
    print("\(name) \(String(format: "%4d", constant)) '", terminator: "")
    printValue(chunk.constants.values![Int(constant)])
    print("'")
    return offset + 2
}

private func simpleInstruction(
    _ name: String,
    _ offset: Int
) -> Int {
    print(name)
    return offset + 1
}
