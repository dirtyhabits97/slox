//
//  File.swift
//  
//
//  Created by user on 1/08/21.
//

import Foundation

final class Scanner {

    private let source: String
    private var tokens: [Token] = []

    private var start: String.Index
    private var current: String.Index
    private var line = 1

    private var isAtEnd: Bool { current != source.endIndex }

    init(source: String) {
        self.source = source
        start = source.startIndex
        current = source.startIndex
    }

    func scanTokens() -> [Token] {
        while !isAtEnd {
            // We are at the beginning of the next lexeme
            start = current
            scanToken()
        }

        tokens.append(Token(type: .EOF, lexeme: "", literal: nil, line: line))
        return tokens
    }

    private func scanToken() {
        let charToEvaluate = advance()
        switch charToEvaluate {
        case "(": addToken(type: .LEFT_PAREN)
        case ")": addToken(type: .RIGHT_PAREN)
        case "{": addToken(type: .LEFT_BRACE)
        case "}": addToken(type: .RIGHT_BRACE)
        case ",": addToken(type: .COMMA)
        case ".": addToken(type: .DOT)
        case "-": addToken(type: .MINUS)
        case "+": addToken(type: .PLUS)
        case ";": addToken(type: .SEMICOLON)
        case "*": addToken(type: .STAR)

        case "!": addToken(type: match("=") ? .BANG_EQUAL : .BANG)
        case "=": addToken(type: match("=") ? .EQUAL_EQUAL : .EQUAL)
        case "<": addToken(type: match("=") ? .LESS_EQUAL : .LESS)
        case ">": addToken(type: match("=") ? .GREATER_EQUAL : .GREATER)

        default:
            Lox.error(line: line, message: "Unexpected character.")
        }
    }

    private func advance() -> Character {
        defer { current = source.index(after: current) }
        return source[current]
    }

    private func addToken(type: TokenType, literal: AnyObject? = nil) {
        let text = String(source[start...current])
        tokens.append(Token(type: type, lexeme: text, literal: literal, line: line))
    }

    private func match(_ expected: Character) -> Bool {
        if isAtEnd { return false }
        if source[current] != expected { return false }

        current = source.index(after: current)
        return true
    }
}
