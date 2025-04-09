//
//  MarkdownDocumentListViewModel.swift
//  md_editor
//
//  Created by 松尾宏規 on 2025/04/08.
//

import RealmSwift
import RxSwift
import RxCocoa
import Foundation

final class MarkdownDocumentListViewModel {
    // swiftlint:disable:next force_try
    private let realm: Realm = try! Realm()
    let documents = BehaviorRelay<[Document]>(value: [])
    
    init() {
        fetchAll()
    }
    
    func fetchAll() {
        let results = realm.objects(Document.self).sorted(byKeyPath: "createdAt", ascending: false)
        documents.accept(Array(results))
    }
    
    func searchDocuments(with keyword: String) {
        let results = realm.objects(Document.self).filter("title CONTAINS[c] %@", keyword).sorted(byKeyPath: "createdAt", ascending: false)
        documents.accept(Array(results))
    }
    
    func addDocument(title: String, content: String) {
        let document = Document()
        document.title = title
        document.content = content
        document.createdAt = Date()
        // swiftlint:disable:next force_try
        try! realm.write {
            realm.add(document)
        }
        fetchAll()
    }
    
    func deleteDocument(_ document: Document) {
        // swiftlint:disable:next force_try
        try! realm.write {
            realm.delete(document)
        }
        fetchAll()
    }
    
    func updateDocumentTitle(document: Document, newTitle: String) {
        // swiftlint:disable:next force_try
        try! realm.write {
            document.title = newTitle
        }
        fetchAll()
    }
    
    func updateDocumentContent(document: Document, newContent: String) {
        // swiftlint:disable:next force_try
        try! realm.write {
            document.content = newContent
            document.updatedAt = Date()
            
            if let firstLine  = newContent.split(separator: "\n").first, !firstLine.trimmingCharacters(in: .whitespaces).isEmpty {
                document.title = firstLine.replacingOccurrences(of: "#", with: "").replacingOccurrences(of: " ", with: "")
            }
        }
    }
}
