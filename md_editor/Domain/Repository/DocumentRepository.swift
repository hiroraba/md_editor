//
//  DocumentRepository.swift
//  md_editor
//  
//  Created by matsuohiroki on 2025/04/16.
//  
//

import Foundation

protocol DocumentRepository {
    func fetchAll() -> [Document]
    func search(keyword: String) -> [Document]
    func add(title: String, content: String)
    func delete(document: Document)
    func updateTitle(document: Document, newTitle: String)
    func updateContent(document: Document, newContent: String)
}
