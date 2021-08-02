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
    let literal: Any?
    let line: Int

    var description: String {
        if let literal = literal {
            return "\(type) \(lexeme) \(literal)"
        }
        return "\(type) \(lexeme)"
    }
}
