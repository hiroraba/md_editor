//
//  MarkDownParser.swift
//  md_editor
//
//  Created by 松尾宏規 on 2025/04/07.
//

import Foundation
import Ink

final class MarkDownParser {
    private let parser = Ink.MarkdownParser()
    
    func convertToHTML(markdown: String, theme: EditorTheme) -> String {
        let body = parser.html(from: markdown)
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
                \(theme.css())
                h1, h2, h3 {
                    margin-top: 1em;
                }
                pre {
                    background: #f0f0f0;
                    padding: 1em;
                    overflow-x: auto;
                }
                code {
                    background: #e0e0e0;
                    padding: 0.2em 0.4em;
                    border-radius: 4px;
                }
            </style>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }
}
