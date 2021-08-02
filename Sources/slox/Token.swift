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
    let literal: AnyObject
    let line: Int

    var description: String {
        "\(type) \(lexeme) \(literal)"
    }
}
