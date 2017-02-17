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
    
    var currentWordIsNotAParameterName: Bool {
        return previousWord != "."
    }
    
    var shouldIgnoreCurrentWord: Bool {
        return forbiddenZone != nil
    }
    
    var wordSuccedingClassStringIsActuallyAProtectableClass: Bool {
        return currentWord.isNotUsingClassAsAParameterNameOrProtocol && currentWord.isNotScopeIdentifier && currentWord.isNotASwiftStandardClass
    }
    
    func stopIgnoringWordsIfNeeded() {
        if currentWord == forbiddenZone?.zoneEnd {
            forbiddenZone = nil
        }
    }
    
    func protectNextWordIfNeeded() {
        guard (currentWord == "class" || (structs && currentWord == "struct")) && currentWordIsNotAParameterName else {
            return
        }
        shouldProtectNextWord = true
    }
    
    func startIgnoringWordsIfNeeded() {
        forbiddenZone = ForbiddenZone(rawValue: currentWord)
    }

    func prepareForNextWord() {
        previousWord = currentWord
    }
}
