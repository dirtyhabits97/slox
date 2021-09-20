//
//  File.swift
//  
//
//  Created by user on 20/09/21.
//

import Foundation

typealias Value = Double

struct ValueArray {

    var capacity: Int
    var count: Int
    var values: UnsafeMutablePointer<Value>?

    init() {
        capacity = 0
        count = 0
        values = nil
    }
}

func initValueArray(_ array: inout ValueArray) {
    array.capacity = 0
    array.count = 0
    array.values = nil
}

func writeValueArray(_ array: inout ValueArray, value: Value) {
    if array.capacity < array.count + 1 {
        let oldCapacity = array.capacity
        array.capacity = GROW_CAPACITY(array.capacity)
        array.values = GROW_ARRAY(pointer: array.values, oldSize: oldCapacity, newSize: array.capacity)
    }

    array.values?[array.count] = value
    array.count += 1
}

func freeValueArray(_ array: inout ValueArray) {
    FREE_ARRAY(
        pointer: array.values,
        oldSize: array.capacity
    )
    initValueArray(&array)
}

func printValue(_ value: Value) {
    print(String(format: "%g", value), terminator: "")
}
