//
//  SwiftFileScanData.swift
//  swiftshield
//
//  Created by Bruno Rocha on 1/18/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Foundation

enum SwiftFileScanDataPhase {
    case reading
    case overwriting
}

class SwiftFileScanData {
    let phase: SwiftFileScanDataPhase
    var currentWord = ""
    var shouldProtectNextWord = false
    var forbiddenZone: ForbiddenZone? = nil
    var previousWord = ""
    
    var currentWordIsNotAParameterName: Bool {
        return previousWord != "."
    }
    
    var currentWordIsNotAFramework: Bool {
        return previousWord != "import"
    }
    
    var shouldIgnoreCurrentWord: Bool {
        return forbiddenZone != nil
    }
    
    var wordSuccedingClassStringIsActuallyAProtectableClass: Bool {
        return currentWord.isNotUsingClassAsAParameterNameOrProtocol && currentWord.isNotScopeIdentifier && currentWord.isNotASwiftStandardClass
    }
    
    init(phase: SwiftFileScanDataPhase) {
        self.phase = phase
    }
    
    func stopIgnoringWordsIfNeeded() {
        if currentWord == forbiddenZone?.zoneEnd {
            forbiddenZone = nil
        }
    }
    
    func protectNextWordIfNeeded() {
        guard (currentWord == "class" || currentWord == "struct" || currentWord == "enum" || currentWord == "protocol") && currentWordIsNotAParameterName && currentWordIsNotAFramework else {
            return
        }
        shouldProtectNextWord = true
    }
    
    func startIgnoringWordsIfNeeded() {
        forbiddenZone = ForbiddenZone(rawValue: currentWord)
    }

    func prepareForNextWord() {
        if phase == .reading {
            previousWord = currentWord
        }
    }
}
