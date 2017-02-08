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
    let interpolatedStringZone = InterpolatedStringZone()
    
    var currentWordIsNotAParameterName: Bool {
        return previousWord != "."
    }
    
    var currentWordIsNotAFramework: Bool {
        return previousWord != "import"
    }
    
    var currentWordIsNotAStandardSwiftClass: Bool {
        switch previousWord {
        case ".":
            return previousPreviousWord != "Swift" && previousPreviousWord.isNotASwiftStandardClass
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
    
    var classDeclaractionFollowsSwiftNamingConventions: Bool {
        guard let firstCharacter = currentWord.characters.first else {
            return false
        }
        let firstLetter = String(describing: firstCharacter)
        return firstLetter.uppercased() == firstLetter
    }
    
    var isNotASwiftStandardClass: Bool {
        return currentWord.isNotASwiftStandardClass
    }
    
    var beginOfInterpolatedZone: Bool {
        if (forbiddenZone == .quote || forbiddenZone == .doubleQuote) && previousWord == "(" && previousPreviousWord == "\\" {
            interpolatedStringZone.storedForbiddenZones.append(forbiddenZone!)
            forbiddenZone = nil
            return true
        }
        return false
    }
    
    init(phase: SwiftFileScanDataPhase) {
        self.phase = phase
    }
    
    func stopIgnoringWordsIfNeeded() {
        if currentWord == forbiddenZone?.zoneEnd {
            //Dont end the zone if it's an escaped quote
            if forbiddenZone == .quote || forbiddenZone == .doubleQuote && previousWord == "\\" {
                return
            }
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
        let newZone = ForbiddenZone(rawValue: currentWord)
        if interpolatedStringZone.storedForbiddenZones.count > 1 {
            if currentWord == forbiddenZone?.zoneEnd && previousWord == ")" {
                forbiddenZone = interpolatedStringZone.storedForbiddenZones.popLast()
                return
            }
        }
        forbiddenZone = newZone
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
}
