//
//  NSColor+.swift
//  md_editor
//
//  Created by matsuohiroki on 2025/04/08.
//

import AppKit

extension NSColor {
    convenience init?(hex: String) {
        let hexSanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hexSanitized).scanHexInt64(&int)

        let a, r, g, b: UInt64 // swiftlint:disable:this identifier_name
        switch hexSanitized.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17,
                                  (int >> 4 & 0xF) * 17,
                                  (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16,
                                  int >> 8 & 0xFF,
                                  int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24,
                           int >> 16 & 0xFF,
                           int >> 8 & 0xFF,
                           int & 0xFF)
        default:
            return nil
        }

        self.init(red: CGFloat(r) / 255,
                  green: CGFloat(g) / 255,
                  blue: CGFloat(b) / 255,
                  alpha: CGFloat(a) / 255)
    }
}
