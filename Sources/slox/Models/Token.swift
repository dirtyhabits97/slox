//
//  File.swift
//  
//
//  Created by user on 1/08/21.
//

import Foundation

struct Token: Hashable {

    let type: TokenType
    let lexeme: String
    let literal: Literal?
    let line: Int
}

extension Token: CustomStringConvertible {

    var description: String {
        if let literal = literal {
            return "\(type) \(lexeme) \(literal)"
        }
        return "\(type) \(lexeme)"
    }
}
