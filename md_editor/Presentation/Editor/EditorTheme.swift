//
//  EditorTheme.swift
//  md_editor
//
//  Created by matsuohiroki on 2025/04/07.
//

import AppKit

enum EditorTheme {
    case light
    case dark
    case system
    
    var backgroundColorHexString: String {
        switch self {
        case .system:
            let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark ? "#262626" : "#ffffff"
        case .light:
            return "#ffffff"
        case .dark:
            return "#262626"
        }
    }
    
    var textColorHexString: String {
        switch self {
        case .system:
            let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark ? "#ffffff" : "#000000"
        case .light:
                return "#000000"
        case .dark:
            return "#ffffff"
        }
    }
        
    func css() -> String {
        switch self {
        case .system:
            return """
                body {
                    font-family: -apple-system;
                    padding: 2em;
                }
                @media (prefers-color-scheme: dark) {
                    body { color: #eee; background-color: \(backgroundColorHexString); }
                }
                """
        case .light, .dark:
            // swiftlint:disable:next line_length
            return "body { font-family: -apple-system; padding: 2em; color: \(textColorHexString); background: \(backgroundColorHexString); }"
        }
    }
}
