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

    private var isAtEnd: Bool { current >= source.endIndex }

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

        case "/":
            if match("/") {
                // A comment goes until the end of the line.
                while peek() != "\n" && !isAtEnd { advance() }
            } else {
                addToken(type: .SLASH)
            }

        // Ignore whitespaces
        case " ", "\r", "\t": break

        // Move to next line
        case "\n": line += 1

        case "\"": string()

        default:
            if isDigit(charToEvaluate) {
                number()
            // Assume any lexeme starting with a letter or underscore is an identifier
            } else if isAlpha(charToEvaluate) {
                identifier()
            } else {
                Lox.error(line: line, message: "Unexpected character.")
            }
        }
    }

    @discardableResult
    private func advance() -> Character {
        defer { current = source.index(after: current) }
        return source[current]
    }

    private func addToken(type: TokenType, literal: Literal? = nil) {
        let text = String(source[start..<current])
        tokens.append(Token(type: type, lexeme: text, literal: literal, line: line))
    }

    private func match(_ expected: Character) -> Bool {
        if isAtEnd { return false }
        if source[current] != expected { return false }

        current = source.index(after: current)
        return true
    }

    private func peek() -> Character {
        if isAtEnd { return "\0" }
        return source[current]
    }

    private func string() {
        // move until the end of the string (")
        while peek() != "\"" && !isAtEnd {
            if peek() == "\n" { line += 1 }
            advance()
        }

        if isAtEnd {
            Lox.error(line: line, message: "Unterminated string.")
            return
        }

        // The closing "
        advance()

        // Trim the surrounding quotes
        let value = source[source.index(after: start)..<source.index(before: current)]
        addToken(type: .STRING, literal: .string(from: value))
    }

    private func isDigit(_ char: Character) -> Bool {
        char >= "0" && char <= "9"
    }

    private func number() {
        while isDigit(peek()) { advance() }

        // Look for a fractional part
        if peek() == "." && isDigit(peekNext()) {
            // Consume the "."
            advance()

            while isDigit(peek()) { advance() }
        }

        let str = source[start..<current]
        addToken(type: .NUMBER, literal: .number(from: str))
    }

    private func peekNext() -> Character {
        if isAtEnd || source.index(after: current) == source.endIndex {
            return "\0"
        }
        return source[source.index(after: current)]
    }

    private func isAlpha(_ char: Character) -> Bool {
        return (char >= "a" && char <= "z") ||
               (char >= "A" && char <= "Z") ||
                char == "_"
    }

    private func identifier() {
        while isAlphaNumeric(peek()) { advance() }

        let text = source[start..<current]
        addToken(type: Scanner.keywords[text] ?? .IDENTIFIER)
    }

    private func isAlphaNumeric(_ char: Character) -> Bool {
        isDigit(char) || isAlpha(char)
    }
}

private extension Scanner {

    static let keywords: [String.SubSequence: TokenType] = [
           "and": .AND,
         "class": .CLASS,
          "else": .ELSE,
         "false": .FALSE,
           "for": .FOR,
           "fun": .FUN,
            "if": .IF,
           "nil": .NIL,
            "or": .OR,
         "print": .PRINT,
        "return": .RETURN,
         "super": .SUPER,
          "this": .THIS,
          "true": .TRUE,
           "var": .VAR,
         "while": .WHILE
    ]
}
