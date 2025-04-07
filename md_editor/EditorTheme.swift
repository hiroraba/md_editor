//
//  EditorTheme.swift
//  md_editor
//
//  Created by 松尾宏規 on 2025/04/07.
//

import Foundation

enum EditorTheme {
    case light
    case dark
    case system
    
    func css() -> String {
            switch self {
            case .system:
                return """
                body {
                    font-family: -apple-system;
                    padding: 2em;
                }
                @media (prefers-color-scheme: dark) {
                    body { color: #eee; background-color: #1e1e1e; }
                }
                """
            case .light:
                return "body { font-family: -apple-system; padding: 2em; color: #000; background: #fff; }"
            case .dark:
                return "body { font-family: -apple-system; padding: 2em; color: #eee; background: #1e1e1e; }"
            }
        }
    
}
