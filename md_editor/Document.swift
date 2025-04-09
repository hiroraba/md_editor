//
//  Document.swift
//  md_editor
//
//  Created by 松尾宏規 on 2025/04/08.
//

import RealmSwift
import Foundation

final class Document: Object, Identifiable {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var title: String
    @Persisted var content: String
    @Persisted var createdAt: Date
    @Persisted var updatedAt: Date?
}
