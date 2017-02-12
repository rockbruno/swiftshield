//
//  ErrorData.swift
//  swiftshield
//
//  Created by Bruno Rocha on 2/8/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Cocoa

struct ErrorData {
    let file: File
    let line: Int
    let column: Int
    let error: String
    let target: String
    let fullError: String
    
    init?(fullError: String) {
        let separated = fullError.components(separatedBy: ":")
        let file = File(filePath: separated[0])
        let line = Int(separated[1])!
        let column = Int(separated[2])!
        let separatedError = separated[4].components(separatedBy: "'")
        let specificError = separatedError[0].noSpaces
        let target = separatedError[1]
        
        self.file = file
        self.line = line
        self.error = specificError
        self.fullError = fullError
        
        switch error {
        case "cannot call value of non-function type":
            if fullError.contains("module<") == false {
                return nil
            }
            var newTarget = fullError.components(separatedBy: "module<")[1].components(separatedBy: ">")[0]
            self.column = column - newTarget.characters.count
            self.target = newTarget
        case "no such module", "could not build Objective-C module", "value of type", "cannot invoke initializer for type", "initializer for conditional binding must have Optional type, not":
            return nil
        case "type": //type 'nrjCKwImewhNjhC.acDjfj3kfnc' has no member 'ScaleMode'
            let descriptionIndex = separatedError.count > 5 ? 4 : 2
            let secondErrorPart = separatedError[descriptionIndex].noSpaces
            if secondErrorPart.contains("has no member") {
                self.column = column + (target.components(separatedBy: ".")).last!.characters.count + 1
                self.target = separatedError[descriptionIndex + 1]
            } else if secondErrorPart.contains("does not conform to protocol"){
                return nil
            } else {
                self.column = column
                self.target = target
            }
        case "":
            let description = separatedError[2].noSpaces
            if description.contains("is not a member type of") {
                self.column = column
                self.target = target
            } else if description.contains("does not have a member type named") {
                self.column = column
                self.target = separatedError[3]
            } else {
                return nil
            }
        default:
            self.column = column
            self.target = target
        }
    }
    
    init(file: File, line: Int, column: Int) {
        self.file = file
        self.line = line
        self.column = column
        self.error = "Injected error"
        self.target = "Injected error"
        self.fullError = "Injected error"
    }
    
    var isModuleHasNoMemberError: Bool {
        return self.error == "module"
    }
}
