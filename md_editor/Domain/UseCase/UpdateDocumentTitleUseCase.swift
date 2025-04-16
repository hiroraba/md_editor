//
//  UpdateDocumentTitleUseCase.swift
//  md_editor
//  
//  Created by matsuohiroki on 2025/04/16.
//  
//

import Foundation

final class UpdateDocumentTitleUseCase {
    private let repository: DocumentRepository

    init(repository: DocumentRepository = RealmDocumentRepository()) {
        self.repository = repository
    }

    func execute(document: Document, newTitle: String) {
        repository.updateTitle(document: document, newTitle: newTitle)
    }
}
