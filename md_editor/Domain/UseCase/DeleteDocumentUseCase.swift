//
//  DeleteDocumentUseCase.swift
//  md_editor
//  
//  Created by matsuohiroki on 2025/04/16.
//  
//

import Foundation

final class DeleteDocumentUseCase {
    private let repository: DocumentRepository

    init(repository: DocumentRepository = RealmDocumentRepository()) {
        self.repository = repository
    }

    func execute(document: Document) {
        repository.delete(document: document)
    }
}
