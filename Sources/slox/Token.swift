//
//  File.swift
//  
//
//  Created by user on 1/08/21.
//

import Foundation

struct Token: CustomStringConvertible {

    let type: TokenType
    let lexeme: String
    let literal: Literal?
    let line: Int

    var description: String {
        if let literal = literal {
            return "\(type) \(lexeme) \(literal)"
        }
        return "\(type) \(lexeme)"
    }
}

// source: https://github.com/heckj/Slox/blob/main/Sources/Slox/LoxTokens.swift
enum Literal {

    case string(String)
    case number(Double)

    init(_ str: Substring) {
        self = .string(String(str))
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
            return str
        case .number(let num):
            return String(num)
        }
    }
}
