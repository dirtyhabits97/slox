//
//  File.swift
//  
//
//  Created by user on 29/08/21.
//

import Foundation

// source: https://github.com/heckj/Slox/blob/main/Sources/Slox/LoxTokens.swift
enum Literal: Hashable {

    case string(String)
    case number(Double)
    case bool(Bool)
    case none

    static func string<S: StringProtocol>(from str: S) -> Literal {
        .string(String(str))
    }

    static func number<S: StringProtocol>(from str: S) -> Literal? {
        if let number = Double(String(str)) { return .number(number) }
        return nil
    }
}

extension Literal: CustomStringConvertible {

    var description: String {
        switch self {
        case .string(let str):
            return "\"\(str)\""
        case .number(let num):
            return String(num)
        case .bool(let bool):
            return String(bool)
        case .none:
            return "nil"
        }
    }
}
