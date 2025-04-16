//
//  DocumentListViewModel.swift
//  md_editor
//
//  Created by 松尾宏規 on 2025/04/08.
//

import Foundation
import RxSwift
import RxRelay

final class DocumentListViewModel {
    private let fetchDocumentsUseCase: FetchDocumentsUseCase
    private let searchDocumentsUseCase: SearchDocumentsUseCase
    private let addDocumentUseCase: AddDocumentUseCase
    private let deleteDocumentUseCase: DeleteDocumentUseCase
    private let updateDocumentTitleUseCase: UpdateDocumentTitleUseCase
    private let updateDocumentContentUseCase: UpdateDocumentContentUseCase
    
    let documents = BehaviorRelay<[Document]>(value: [])
    private let disposeBag = DisposeBag()
    
    init(fetchDocumentsUseCase: FetchDocumentsUseCase = FetchDocumentsUseCase(),
         searchDocumentsUseCase: SearchDocumentsUseCase = SearchDocumentsUseCase(),
         addDocumentUseCase: AddDocumentUseCase = AddDocumentUseCase(),
         deleteDocumentUseCase: DeleteDocumentUseCase = DeleteDocumentUseCase(),
         updateDocumentTitleUseCase: UpdateDocumentTitleUseCase = UpdateDocumentTitleUseCase(),
         updateDocumentContentUseCase: UpdateDocumentContentUseCase = UpdateDocumentContentUseCase()) {
        self.fetchDocumentsUseCase = fetchDocumentsUseCase
        self.searchDocumentsUseCase = searchDocumentsUseCase
        self.addDocumentUseCase = addDocumentUseCase
        self.deleteDocumentUseCase = deleteDocumentUseCase
        self.updateDocumentTitleUseCase = updateDocumentTitleUseCase
        self.updateDocumentContentUseCase = updateDocumentContentUseCase
        
        fetchAll()
    }
    
    func fetchAll() {
        documents.accept(fetchDocumentsUseCase.execute())
    }
    
    func searchDocuments(with keyword: String) {
        documents.accept(searchDocumentsUseCase.execute(keyword: keyword))
    }
    
    func addDocument(title: String, content: String) {
        addDocumentUseCase.execute(title: title, content: content)
        fetchAll()
    }
    
    func deleteDocument(_ document: Document) {
        deleteDocumentUseCase.execute(document: document)
        fetchAll()
    }
    
    func updateDocumentTitle(document: Document, newTitle: String) {
        updateDocumentTitleUseCase.execute(document: document, newTitle: newTitle)
        fetchAll()
    }
    
    func updateDocumentContent(document: Document, newContent: String) {
        updateDocumentContentUseCase.execute(document: document, newContent: newContent)
    }
}
