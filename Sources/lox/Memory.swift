//
//  File.swift
//  
//
//  Created by user on 19/09/21.
//
// size vs stride
// https://stackoverflow.com/a/27640066

import Foundation
import CoreText

func GROW_CAPACITY(_ capacity: Int) -> Int {
    capacity < 8 ? 8 : capacity * 2
}

func GROW_ARRAY<T>(
    pointer: UnsafeMutablePointer<T>?,
    oldSize: Int, // size_t
    newSize: Int  // size_t
) -> UnsafeMutablePointer<T>? {
    let size = MemoryLayout<T>.stride
    return reallocate(
        pointer: pointer,
        oldSize: size * oldSize,
        newSize: size * newSize
    )
}

@discardableResult
func FREE_ARRAY<T>(
    pointer: UnsafeMutablePointer<T>?,
    oldSize: Int // size_t
) -> UnsafeMutablePointer<T>? {
    reallocate(
        pointer: pointer,
        oldSize: MemoryLayout<T>.stride * oldSize,
        newSize: 0
    )
}

private func reallocate<T>(
    pointer: UnsafeMutablePointer<T>?,
    oldSize: Int,
    newSize: Int
) -> UnsafeMutablePointer<T>? {
    if newSize == 0 {
        free(pointer)
        return nil
    }
    let result = realloc(pointer, newSize)
    if result == nil { exit(1) }
    return result?.assumingMemoryBound(to: T.self)
}
