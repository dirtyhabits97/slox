//
//  File.swift
//  
//
//  Created by user on 19/09/21.
//

import Foundation

var chunk = Chunk()

let constant = addConstant(&chunk, value: 1.2)
writeChunk(&chunk, byte: OpCode.OP_CONSTANT.rawValue, line: 123)
writeChunk(&chunk, byte: UInt8(constant), line: 123)

writeChunk(&chunk, byte: OpCode.OP_RETURN.rawValue, line: 123)

disassembleChunk(&chunk, name: "test chunk")
freeChunk(&chunk)
