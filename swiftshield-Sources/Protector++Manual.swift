//
//  Protector++Manual.swift
//  swiftshield
//
//  Created by Bruno Rocha on 4/22/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Cocoa

extension Protector {
    func findAndProtectReferencesManually(tag: String, files: [File]) -> ObfuscationData {
        Logger.log(.scanningDeclarations)
        let obfsData = ObfuscationData()
        for file in files {
            Logger.log(.checking(file: file))
            do {
                let data = try String(contentsOfFile: file.path, encoding: .utf8)
                var currentIndex = data.startIndex
                let matches = data.match(regex: String.regexFor(tag: tag))
                let newFile: String = matches.flatMap { result in
                    let word = (data as NSString).substring(with: result.rangeAt(0))
                    let protectedName: String = {
                        guard let protected = obfsData.obfuscationDict[word] else {
                            let protected = String.random(length: protectedClassNameSize)
                            obfsData.obfuscationDict[word] = protected
                            return protected
                        }
                        return protected
                    }()
                    Logger.log(.protectedReference(originalName: word, protectedName: protectedName))
                    let range: Range = currentIndex..<data.index(data.startIndex, offsetBy: result.range.location)
                    currentIndex = data.index(range.upperBound, offsetBy: result.range.length)
                    return data.substring(with: range) + protectedName
                    }.joined() + (currentIndex < data.endIndex ? data.substring(with: currentIndex..<data.endIndex) : "")
                try newFile.write(toFile: file.path, atomically: false, encoding: String.Encoding.utf8)
            } catch {
                Logger.log(.fatal(error: error.localizedDescription))
                exit(1)
            }
        }
        return obfsData
    }
}
