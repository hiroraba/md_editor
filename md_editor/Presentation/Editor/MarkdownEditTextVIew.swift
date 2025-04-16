//
//  MarkdownEditTextVIew.swift
//  md_editor
//
//  Created by matsuohiroki on 2025/04/08.
//

import AppKit

protocol MarkDownEditTextViewDelegate: AnyObject {
    func textView(_ textView: MarkDownEditTextView, didLoadMarkdown text: String)
}

class MarkDownEditTextView: NSTextView {
    
    weak var markdownDelegate: MarkDownEditTextViewDelegate?
    
    // swiftlint:disable:next line_length
    override func dragOperation(for dragInfo: any NSDraggingInfo, type: NSPasteboard.PasteboardType) -> NSDragOperation {
        return .copy
    }
    
    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        if let filePath = pasteboard.propertyList(forType: .fileURL) as? String,
           let fileURL = URL(string: filePath) {
            do {
                let fileContents = try String(contentsOf: fileURL, encoding: .utf8)
                self.string = fileContents
                markdownDelegate?.textView(self, didLoadMarkdown: fileContents)
                return true
            } catch {
                print("ファイルの読み込み中にエラーが発生しました: \(error)")
            }
        }
        return false
    }
}
