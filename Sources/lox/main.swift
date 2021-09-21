//
//  File.swift
//  
//
//  Created by user on 19/09/21.
//

import Foundation

initVM()

var chunk = Chunk()

var constant = addConstant(&chunk, value: 1.2)
writeChunk(&chunk, byte: OpCode.OP_CONSTANT.rawValue, line: 123)
writeChunk(&chunk, byte: UInt8(constant), line: 123)

constant = addConstant(&chunk, value: 3.4)
writeChunk(&chunk, byte: OpCode.OP_CONSTANT.rawValue, line: 123)
writeChunk(&chunk, byte: UInt8(constant), line: 123)

writeChunk(&chunk, byte: OpCode.OP_ADD.rawValue, line: 123)

constant = addConstant(&chunk, value: 5.6)
writeChunk(&chunk, byte: OpCode.OP_CONSTANT.rawValue, line: 123)
writeChunk(&chunk, byte: UInt8(constant), line: 123)

writeChunk(&chunk, byte: OpCode.OP_DIVIDE.rawValue, line: 123)
writeChunk(&chunk, byte: OpCode.OP_NEGATE.rawValue, line: 123)

writeChunk(&chunk, byte: OpCode.OP_RETURN.rawValue, line: 123)

interpret(&chunk)
freeVM()
freeChunk(&chunk)
