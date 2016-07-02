//
//  SourceEditorCommand.swift
//  CleanClosure
//
//  Created by Patrick Balestra on 6/18/16.
//  Copyright © 2016 Patrick Balestra. All rights reserved.
//

import Foundation
import XcodeKit

extension NSString {
    // Remove the given chracters in the range from the string.
    func remove(characters: [Character], in range: NSRange) -> NSString {
        var cleanedString = self
        for char in characters {
            cleanedString = cleanedString.replacingOccurrences(of: String(char), with: "", options: .caseInsensitiveSearch, range: range)
        }
        return cleanedString
    }
}

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: (NSError?) -> Void ) -> Void {
        var updatedLineIndexes = [Int]()
        
        // Find lines that contain a closure syntax
        for lineIndex in 0 ..< invocation.buffer.lines.count {
            let line = invocation.buffer.lines[lineIndex] as! NSString
            do {
                let regex = try RegularExpression(pattern: "\\{.*\\(.+\\).+in", options: .caseInsensitive)
                let range = NSRange(0 ..< line.length)
                let results = regex.matches(in: line as String, options: .reportProgress, range: range)
                // When a closure is found, clean up its syntax
                _ = results.map { result in
                    let cleanLine = line.remove(characters: ["(", ")"], in: result.range)
                    updatedLineIndexes.append(lineIndex)
                    invocation.buffer.lines[lineIndex] = cleanLine
                }
            } catch {
                completionHandler(error as NSError)
            }
        }
        
        // If at least a line was changed, create an array of changes and pass it to the buffer selections.
        if updatedLineIndexes.count > 0 {
            let updatedSelections: [XCSourceTextRange] = updatedLineIndexes.map { lineIndex in
                let lineSelection = XCSourceTextRange()
                lineSelection.start = XCSourceTextPosition(line: lineIndex, column: 0)
                lineSelection.end = XCSourceTextPosition(line: lineIndex, column: 0)
                return lineSelection
            }
            invocation.buffer.selections.setArray(updatedSelections)
        }
        
        completionHandler(nil)
    }
}
