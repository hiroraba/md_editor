//
//  RealmDocumentRepository.swift
//  md_editor
//  
//  Created by matsuohiroki on 2025/04/16.
//  
//

import Foundation
import RealmSwift

final class RealmDocumentRepository: DocumentRepository {
    private let realm: Realm

    init() {
        // swiftlint:disable:next force_try
        self.realm = try! Realm()
    }

    func fetchAll() -> [Document] {
        let results = realm.objects(Document.self).sorted(byKeyPath: "createdAt", ascending: false)
        return Array(results)
    }

    func search(keyword: String) -> [Document] {
        let results = realm.objects(Document.self)
            .filter("title CONTAINS[c] %@", keyword)
            .sorted(byKeyPath: "createdAt", ascending: false)
        return Array(results)
    }

    func add(title: String, content: String) {
        let document = Document()
        document.title = title
        document.content = content
        document.createdAt = Date()
        // swiftlint:disable:next force_try
        try! realm.write {
            realm.add(document)
        }
    }

    func delete(document: Document) {
        // swiftlint:disable:next force_try
        try! realm.write {
            realm.delete(document)
        }
    }

    func updateTitle(document: Document, newTitle: String) {
        // swiftlint:disable:next force_try
        try! realm.write {
            document.title = newTitle
        }
    }

    func updateContent(document: Document, newContent: String) {
        // swiftlint:disable:next force_try
        try! realm.write {
            document.content = newContent
            document.updatedAt = Date()

            if let firstLine = newContent.split(separator: "\n").first,
               !firstLine.trimmingCharacters(in: .whitespaces).isEmpty {
                document.title = firstLine.replacingOccurrences(of: "#", with: "").replacingOccurrences(of: " ", with: "")
            }
        }
    }
}
