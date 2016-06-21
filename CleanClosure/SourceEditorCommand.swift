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
    func remove(character: String, in range: NSRange) -> NSString {
        return self.replacingOccurrences(of: character, with: "", options: .caseInsensitiveSearch, range: range)
    }
}

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: (NSError?) -> Void ) -> Void {
        
        var updatedLineIndexes = [Int]()
        
        for lineIndex in 0 ..< invocation.buffer.lines.count {
            let line = invocation.buffer.lines[lineIndex] as! NSString
            do {
                let regex = try RegularExpression(pattern: "\\{[\\s]*\\([a-zA-Z0-9_\\-,\\s]+\\)[\\s]*in", options: .caseInsensitive)
                let range = NSRange(location: 0, length: line.length)
                let results = regex.matches(in: line as String, options: .reportProgress, range: range)
                for result in results {
                    let cleanLine = line.remove(character: "(", in: result.range).remove(character: ")", in: result.range)
                    updatedLineIndexes.append(lineIndex)
                    invocation.buffer.lines[lineIndex] = cleanLine
                }
            } catch {
                completionHandler(error as NSError)
            }
        }

        let updatedSelections: [XCSourceTextRange] = updatedLineIndexes.map { lineIndex in
            let lineSelection = XCSourceTextRange()
            lineSelection.start = XCSourceTextPosition(line: lineIndex, column: 0)
            lineSelection.end = XCSourceTextPosition(line: lineIndex, column: 0)
            return lineSelection
        }
        
        if updatedSelections.count > 0 {
            invocation.buffer.selections.setArray(updatedSelections)
        }
        
        completionHandler(nil)
    }
}
