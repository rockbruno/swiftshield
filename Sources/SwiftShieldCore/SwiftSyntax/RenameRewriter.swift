//
//  File.swift
//  
//
//  Created by Binh An Tran on 8/3/22.
//

import Foundation
import SwiftSyntax

final class RenameRewriter: SyntaxRewriter {
    private let names: Set<String>
    private let obfuscate: (String) -> String?
    private let logger: LoggerProtocol

    init(names: Set<String>, logger: LoggerProtocol, obfuscate: @escaping (String) -> String?) {
        self.names = names
        self.obfuscate = obfuscate
        self.logger = logger
    }

    override func visit(_ token: TokenSyntax) -> Syntax {
        guard case .identifier(let text) = token.tokenKind else { return super.visit(token) }
        if names.contains(text) {
            guard let obfuscatedName = obfuscate(text) else {
                return super.visit(token)
            }

            logger.log("* +++ Found \(text) -> now: \(obfuscatedName)")

            let newToken = token.withKind(.identifier(obfuscatedName))
            return super.visit(newToken)
        }
        return super.visit(token)
    }
}
