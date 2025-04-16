//
//  AddDocumentUseCase.swift
//  md_editor
//  
//  Created by matsuohiroki on 2025/04/16.
//  
//

import Foundation

final class AddDocumentUseCase {
    private let repository: DocumentRepository

    init(repository: DocumentRepository = RealmDocumentRepository()) {
        self.repository = repository
    }

    func execute(title: String, content: String) {
        repository.add(title: title, content: content)
    }
}
