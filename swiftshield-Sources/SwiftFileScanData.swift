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
    var previousPreviousWord = ""
    
    var currentWordIsNotAParameterName: Bool {
        return previousWord != "."
    }
    
    var currentWordIsNotAGenericParameter: Bool {
        return previousWord != ","
    }
    
    var currentWordIsNotAFramework: Bool {
        return previousWord != "import"
    }
    
    var currentWordIsNotAStandardSwiftClass: Bool {
        switch previousWord {
        case ".":
            return previousPreviousWord != "Swift"
        case "where":
            return currentWord != "Key" && currentWord != "Value" && currentWord != "Element"
        default:
            return true
        }
    }
    
    var shouldIgnoreCurrentWord: Bool {
        return forbiddenZone != nil
    }
    
    var wordSuccedingClassStringIsActuallyAClass: Bool {
        return currentWord.isNotUsingClassAsAParameterNameOrProtocol && currentWord.isNotScopeIdentifier
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
        guard (currentWord == "class" || currentWord == "struct" || currentWord == "enum") && currentWordIsNotAParameterName && currentWordIsNotAFramework else {
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
        } else {
            if currentWord != "" && currentWord != " " && currentWord != "\n" {
                previousPreviousWord = previousWord
                previousWord = currentWord
            }
        }
    }
    
    func prepareForNextFile() {
        currentWord = ""
        shouldProtectNextWord = false
        forbiddenZone = nil
        previousWord = ""
        previousPreviousWord = ""
    }
}
