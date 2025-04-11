//
//  EditorViewModel.swift
//  md_editor
//
//  Created by matsuohiroki on 2025/04/07.
//

import Foundation
import RxSwift
import RxCocoa

final class EditorViewModel {
    
    let markDownText = BehaviorRelay<String>(value: "")
    let htmlText: Observable<String>
    let theme = BehaviorRelay<EditorTheme>(value: .system)
    
    private let parser = MarkDownParser()
    
    init() {
        let text = markDownText.asObservable()
        let currentTheme = theme.asObservable()
        self.htmlText = Observable.combineLatest(text, currentTheme)
            .map { text, theme in
               var html = MarkDownParser().convertToHTML(markdown: text, theme: theme)
                
                html = html.replacingOccurrences(
                    of: "<h(\\d)>(.*?)</h\\1>",
                    with: "<h$1 id=\"$2\">$2</h$1>",
                    options: .regularExpression
                )
                
                return html
            }
    }
}
