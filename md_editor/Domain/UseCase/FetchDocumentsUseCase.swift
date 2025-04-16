//
//  FetchDocumentUseCase.swift
//  md_editor
//  
//  Created by matsuohiroki on 2025/04/16.
//  
//

import Foundation

final class FetchDocumentsUseCase {
    private let repository: DocumentRepository

    init(repository: DocumentRepository = RealmDocumentRepository()) {
        self.repository = repository
    }

    func execute() -> [Document] {
        return repository.fetchAll()
    }
}
