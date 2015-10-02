//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by 野村 憲男 on 10/2/15.
//  Copyright © 2015 Norio Nomura. All rights reserved.
//

import Cocoa

class ShareViewController: NSViewController {
    
    override var nibName: String? {
        return "ShareViewController"
    }
    
    var latlng: NSString? = nil
    
    @IBOutlet weak var LatLngTextField: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let item = self.extensionContext?.inputItems.first as? NSExtensionItem,
            let attachments = item.attachments?.first as? NSItemProvider else {
                fatalError()
        }
        
        attachments.loadItemForTypeIdentifier(kUTTypeURL as String, options: nil) { url, _ in
            guard let url = url as? NSURL else { return }
            if let latlng = self.getLatLngFromAppleMapsURL(url) ?? self.getLatLngFromGoogleMapsURL(url) {
                self.latlng = latlng
                self.LatLngTextField.cell?.title = latlng
                self.copyButton.enabled = true
            }
        }
    }
    
    @IBOutlet weak var copyButton: NSButtonCell!
    @IBAction func copy(sender: AnyObject?) {
        let outputItem = NSExtensionItem()
        
        if let latlng = latlng {
            let pasteboard = NSPasteboard.generalPasteboard()
            pasteboard.clearContents()
            pasteboard.writeObjects([latlng])
        }
        
        let outputItems = [outputItem]
        self.extensionContext!.completeRequestReturningItems(outputItems, completionHandler: nil)
    }
    
    @IBAction func cancel(sender: AnyObject?) {
        let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
        self.extensionContext!.cancelRequestWithError(cancelError)
    }
    
    /// parse Apple Maps url and return LatLng
    /// - Parameter url: NSURL
    /// - Returns: String of LatLng
    func getLatLngFromAppleMapsURL(url: NSURL) -> String? {
        guard url.host == "maps.apple.com" else { return nil }
        
        let pattern = "(q|sll|ll|h?near)=(-?\\d+\\.\\d+,-?\\d+\\.\\d+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        
        var latlng: String? = nil
        var candidate: String? = nil
        
        if let query = url.query {
            regex.enumerateMatchesInString(query, options: [], range: query.wholeRange) {
                result, flag, stop in
                
                guard let result = result where result.range.location != NSNotFound else {
                    return
                }
                
                let query = query as NSString
                switch query.substringWithRange(result.rangeAtIndex(1)) {
                case "q": fallthrough
                case "sll": fallthrough
                case "ll":
                    latlng = query.substringWithRange(result.rangeAtIndex(2))
                    stop.memory = true
                case hasPrefix("near"):
                    candidate = query.substringWithRange(result.rangeAtIndex(2))
                default:
                    break
                }
            }
        }
        
        return latlng ?? candidate
    }
    
    /// parse Google Maps url and return LatLng
    /// - Parameter url: NSURL
    /// - Returns: String of LatLng
    func getLatLngFromGoogleMapsURL(url: NSURL) -> String? {
        guard let contains = url.host?.containsString("google") where contains else { return nil }
        
        let pattern = "/@(-?\\d+\\.\\d+,-?\\d+\\.\\d+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        return url.path.flatMap { path in
            let range = regex.matchesInString(path, options: [], range: path.wholeRange).first?.rangeAtIndex(1)
            return range.map((path as NSString).substringWithRange)
        }
    }
}

extension String {
    /// Retunrs NSRange that covers a whole of string
    /// - SeeAlso: [How to make `NSRange` for `NSRegularExpression` in Swift. #swiftlang](https://gist.github.com/norio-nomura/c32bdab1c151c9bf5f63)
    var wholeRange: NSRange {
        return NSMakeRange(0, utf16.count)
    }
}

/// [Pattern Matching in Swift By Ole Begemann](http://oleb.net/blog/2015/09/swift-pattern-matching/)
func ~=<T>(pattern: T -> Bool, value: T) -> Bool {
    return pattern(value)
}

/// Returns true iff value begins with prefix
func hasPrefix(prefix: String)(value: String) -> Bool {
    return value.hasPrefix(prefix)
}
