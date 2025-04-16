//
//  SearchDocumentsUseCase.swift
//  md_editor
//  
//  Created by matsuohiroki on 2025/04/16.
//  
//

import Foundation

final class SearchDocumentsUseCase {
    private let repository: DocumentRepository

    init(repository: DocumentRepository = RealmDocumentRepository()) {
        self.repository = repository
    }

    func execute(keyword: String) -> [Document] {
        return repository.search(keyword: keyword)
    }
}
