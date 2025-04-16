//
//  DocumentListTableView.swift
//  md_editor
//
//  Created by 松尾宏規 on 2025/04/08.
//

import AppKit

class DocumentListTableView: NSTableView {
    weak var deletionDelegate: DocumentListTableViewDeletionDelegate?
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 51 { // Delete key
            deletionDelegate?.documentListTableView(self, didDeleteDocumentAt: IndexPath(item: selectedRow, section: selectedColumn))
        } else {
            super.keyDown(with: event)
        }
    }
}

protocol DocumentListTableViewDeletionDelegate: AnyObject {
    func documentListTableView(_ tableView: DocumentListTableView, didDeleteDocumentAt indexPath: IndexPath)
}
