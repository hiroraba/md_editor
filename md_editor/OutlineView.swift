//
//  OutlineView.swift
//  md_editor
//
//  Created by 松尾宏規 on 2025/04/10.
//

import AppKit

final class OutlineView: NSScrollView {
    private let tableView = NSTableView()
    private let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("OutlineColumn"))
    private var items: [OutlineItem] = []
    var onSelect: ((OutlineItem) -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        self.hasVerticalScroller = true
        self.documentView = tableView
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.delegate = self
        tableView.dataSource = self
        tableView.usesAlternatingRowBackgroundColors = true
    }
    
    func updateOutline(with items: [OutlineItem]) {
        self.items = items
        tableView.reloadData()
    }
}

extension OutlineView: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = items[row]
        let cell = NSTableCellView()
        let textField = NSTextField(labelWithString: item.title)
        textField.font = NSFont.systemFont(ofSize: CGFloat(14 - item.level))
        textField.textColor = .labelColor
        cell.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: CGFloat(8 + item.level * 8)),
            textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4),
            textField.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let selected = tableView.selectedRow
        guard selected >= 0 && selected < items.count else { return }
        onSelect?(items[selected])
    }
}

struct OutlineItem {
    let title: String
    let level: Int // 1 = #, 2 = ##, etc.
    let range: NSRange
}
