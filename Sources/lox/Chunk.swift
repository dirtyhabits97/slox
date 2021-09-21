//
//  File.swift
//  
//
//  Created by user on 19/09/21.
//

import Foundation

struct Chunk {

    var count: Int
    var capacity: Int
    var code: UnsafeMutablePointer<UInt8>?
    var lines: UnsafeMutablePointer<Int>?
    var constants: ValueArray

    init() {
        count = 0
        capacity = 0
        code = nil
        lines = nil
        constants = ValueArray()
    }
}

func initChunk(_ chunk: inout Chunk) {
    chunk.count = 0
    chunk.capacity = 0
    chunk.code = nil
}

func writeChunk(
    _ chunk: inout Chunk,
    byte: UInt8,
    line: Int
) {
    if chunk.capacity < chunk.count + 1 {
        let oldCapacity = chunk.capacity
        chunk.capacity = GROW_CAPACITY(chunk.capacity)
        chunk.code = GROW_ARRAY(pointer: chunk.code, oldSize: oldCapacity, newSize: chunk.capacity)
        chunk.lines = GROW_ARRAY(pointer: chunk.lines, oldSize: oldCapacity, newSize: chunk.capacity)
    }

    chunk.code?[chunk.count] = byte
    chunk.lines?[chunk.count] = line
    chunk.count += 1
}

func freeChunk(_ chunk: inout Chunk) {
    FREE_ARRAY(
        pointer: chunk.code,
        oldSize: chunk.capacity
    )
    FREE_ARRAY(
        pointer: chunk.lines,
        oldSize: chunk.capacity
    )
    freeValueArray(&chunk.constants)
    initChunk(&chunk)
}

// MARK: - Constants
// int addConstant(Chunk* chunk, Value value);
func addConstant(_ chunk: inout Chunk, value: Value) -> Int {
    writeValueArray(&chunk.constants, value: value)
    return chunk.constants.count - 1
}

// MARK: - Codes

enum OpCode: UInt8 {

    case OP_CONSTANT
    case OP_ADD, OP_SUBSTRACT, OP_MULTIPLY, OP_DIVIDE
    case OP_NEGATE
    case OP_RETURN
}
