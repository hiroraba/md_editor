//
//  UpdateDocumentContentUseCase..swift
//  md_editor
//  
//  Created by matsuohiroki on 2025/04/16.
//  
//

import Foundation

final class UpdateDocumentContentUseCase {
    private let repository: DocumentRepository

    init(repository: DocumentRepository = RealmDocumentRepository()) {
        self.repository = repository
    }

    func execute(document: Document, newContent: String) {
        repository.updateContent(document: document, newContent: newContent)
    }
}
