//
//  SwiftFileScanData.swift
//  swiftshield
//
//  Created by Bruno Rocha on 1/18/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Foundation

class SwiftFileScanData {
    var currentWord = ""
    var shouldProtectNextWord = false
    var forbiddenZone: ForbiddenZone? = nil
    var previousWord = ""
    var scope: SwiftScope = .internal
    
    var currentWordIsNotAParameterName: Bool {
        return previousWord != "."
    }
    
    var shouldIgnoreCurrentWord: Bool {
        return forbiddenZone != nil
    }
    
    var wordSuccedingClassStringIsActuallyAProtectableClass: Bool {
        return currentWord.isNotUsingClassAsAParameterNameOrProtocol && currentWord.isNotScopeIdentifier
    }
    
    func stopIgnoringWordsIfNeeded() {
        if currentWord == forbiddenZone?.zoneEnd {
            forbiddenZone = nil
        }
    }
    
    func protectNextWordIfNeeded() {
        guard (currentWord == "class" || currentWord == "struct" || currentWord == "protocol") && currentWordIsNotAParameterName else {
            return
        }
        shouldProtectNextWord = true
    }
    
    func startIgnoringWordsIfNeeded() {
        forbiddenZone = ForbiddenZone(rawValue: currentWord)
    }
    
    func updateScopeIfNeeded() {
        if currentWord == "\n" {
            scope = .internal
        } else {
            if let scope = SwiftScope(rawValue: currentWord) {
                self.scope = scope
            }
        }
    }
    
    func resetScope() {
        scope = .internal
    }

    func prepareForNextWord() {
        previousWord = currentWord
    }
}
