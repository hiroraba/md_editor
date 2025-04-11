//
//  ViewController.swift
//  md_editor
//
//  Created by matsuohiroki on 2025/04/07.
//

import Cocoa
import WebKit
import RxSwift
import RxCocoa

class ViewController: NSViewController, WKNavigationDelegate, NSToolbarDelegate {
    
    private let textView = MarkDownEditTextView()
    private let webView = WKWebView()
    
    private let viewModel = EditorViewModel()
    private let disposeBag = DisposeBag()
    
    private let listViewModel = DocumentListViewModel()
    private let tableView = DocumentListTableView()
    private let searchField = NSSearchField()
    private var selectedDocument: Document? = nil
    
    private let titleLabel = NSTextField(labelWithString: "")
    private let createdAtLabel = NSTextField(labelWithString: "")
    private let updatedAtLabel = NSTextField(labelWithString: "")
    
    private let outlineView = OutlineView()
    
    override func loadView() {
        let splitView = NSSplitView()
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.frame = NSRect(x: 0, y: 0, width: 1000, height: 600)
        
        let leftScrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 500, height: 600))
        leftScrollView.borderType = .bezelBorder
        leftScrollView.hasVerticalScroller = true
        leftScrollView.hasHorizontalScroller = false
        leftScrollView.autoresizingMask = [.width, .height]
        
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = [.width, .height]
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        
        // swiftlint:disable:next line_length
        textView.textContainer?.containerSize = NSSize(width: leftScrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6  // Adjusted to match ruler spacing
        textView.defaultParagraphStyle = paragraphStyle
        textView.typingAttributes[.paragraphStyle] = paragraphStyle
        
        let appearance = NSApp.effectiveAppearance
        let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

        textView.backgroundColor = isDark ? NSColor.textBackgroundColor : NSColor.white
        textView.textColor = isDark ? NSColor.white : NSColor.textColor

        textView.registerForDraggedTypes([.fileURL])
        textView.markdownDelegate = self
        
        leftScrollView.documentView = textView
        
        leftScrollView.rulersVisible = true

        let lineNumberRulerView = LineNumberRulerView(textView: textView)
        leftScrollView.verticalRulerView = lineNumberRulerView

        webView.frame = NSRect(x: 0, y: 0, width: 500, height: 600)
        webView.autoresizingMask = [.width, .height]
        webView.translatesAutoresizingMaskIntoConstraints = true
        webView.navigationDelegate = self
        
        splitView.addArrangedSubview(leftScrollView)
        splitView.addArrangedSubview(webView)
        
        leftScrollView.widthAnchor.constraint(equalTo: webView.widthAnchor).isActive = true
        
        splitView.setHoldingPriority(.defaultLow, forSubviewAt: 0)
        splitView.setHoldingPriority(.defaultLow, forSubviewAt: 1)

        let initialPosition = splitView.frame.width * 0.5
        splitView.setPosition(initialPosition, ofDividerAt: 0)
        
        let documentTableView = NSScrollView()
        documentTableView.hasVerticalScroller = true
        documentTableView.hasHorizontalScroller = false
        documentTableView.borderType = .bezelBorder
        documentTableView.translatesAutoresizingMaskIntoConstraints = false
        
        searchField.placeholderString = "Search Documents"
        searchField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("TitleColumn"))
        column.title = "Documents"
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.usesAlternatingRowBackgroundColors = true
        documentTableView.documentView = tableView
        
        let sideBarStack = NSStackView(views: [searchField, documentTableView])
        sideBarStack.orientation = .vertical
        sideBarStack.translatesAutoresizingMaskIntoConstraints = false
        sideBarStack.spacing = 8
        sideBarStack.widthAnchor.constraint(equalToConstant: 200).isActive = true
        
        splitView.insertArrangedSubview(sideBarStack, at: 0)
        
        let outlineScrollView = outlineView
        outlineScrollView.translatesAutoresizingMaskIntoConstraints = false
        outlineScrollView.widthAnchor.constraint(equalToConstant: 200).isActive = true

        splitView.insertArrangedSubview(outlineScrollView, at: 1)
        
        self.view = splitView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.deletionDelegate = self
        
        NotificationCenter.default.rx.notification(
            NSText.didChangeNotification,
            object: textView
        ).compactMap {[weak self] _ in
            return self?.textView.string
        }.bind(to: viewModel.markDownText)
            .disposed(by: disposeBag)
        
        viewModel.markDownText.observe(on: MainScheduler.instance).subscribe(onNext: { [weak self] text in
            guard let self else { return }
            guard let selectedDocument = self.selectedDocument else { return }
            updateToolbar(for: selectedDocument)
            listViewModel.updateDocumentContent(document: selectedDocument, newContent: text)
            let outlineItems = self.extractOutlineItems(from: text)
            self.outlineView.updateOutline(with: outlineItems)
        }).disposed(by: disposeBag)
        
        viewModel.htmlText
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] html in
                guard let self else { return }
                self.webView.loadHTMLString(html, baseURL: nil)
                self.webView.setValue(false, forKey: "drawsBackground") // make background transparent
            })
            .disposed(by: disposeBag)
        
        viewModel.theme
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] theme in
                guard let self else { return }
                self.textView.backgroundColor = NSColor(hex: theme.backgroundColorHexString)!
                self.textView.textColor = NSColor(hex: theme.textColorHexString)
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(NSText.didChangeNotification, object: textView)
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                (self.textView.enclosingScrollView?.verticalRulerView as? LineNumberRulerView)?.needsDisplay = true
            })
            .disposed(by: disposeBag)
        
        searchField.rx.text.orEmpty.distinctUntilChanged().debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] searchText in
                guard let self else { return }
                if searchText.isEmpty {
                    self.listViewModel.fetchAll()
                } else {
                    self.listViewModel.searchDocuments(with: searchText)
                }
            }).disposed(by: disposeBag)
        
        listViewModel.documents.observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                self.tableView.reloadData()
            }).disposed(by: disposeBag)
        
        outlineView.onSelect = { [weak self] item in
            guard let self else { return }
            if let textView = self.textView as NSTextView? {
                textView.scrollRangeToVisible(item.range)
                textView.setSelectedRange(item.range)
            }
            
            let js = """
            var el = document.getElementById('\(item.title)');
            if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
            """

            self.webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        if view.window?.toolbar == nil {
            let toolbar = NSToolbar(identifier: "MainToolbar")
            toolbar.delegate = self
            toolbar.allowsUserCustomization = false
            toolbar.displayMode = .iconAndLabel
            view.window?.toolbar = toolbar
        }
    }
    
    @objc func openDocument(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.plainText]
        openPanel.allowsMultipleSelection = false
        openPanel.begin(completionHandler: { response in
            guard response == .OK, let url = openPanel.url else { return }
            if let content = try? String(contentsOf: url, encoding: .utf8) {
                self.textView.string = content
                self.viewModel.markDownText.accept(content)
            }
        })
    }
    
    @objc func saveDocument(_ sender: Any) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "Untitled.md"
        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }
            do {
                try self.textView.string.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                print("Error saving file: \(error)")
            }
        }
    }
    
    @objc func newDocument(_ sender: Any) {
        listViewModel.addDocument(title: "new", content: "")
    }
    
    @objc func themeChanged(_ sender: NSPopUpButton) {
        switch sender.indexOfSelectedItem {
        case 0: viewModel.theme.accept(.system)
        case 1: viewModel.theme.accept(.light)
        case 2: viewModel.theme.accept(.dark)
        default: break
        }
    }
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        return true
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.metaInfo, .flexibleSpace, .themeSelector]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.metaInfo, .flexibleSpace, .themeSelector]
    }
    
    // swiftlint:disable:next line_length
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if itemIdentifier == .themeSelector {
            let popup = NSPopUpButton()
            popup.addItems(withTitles: ["System", "Light", "Dark"])
            popup.target = self
            popup.action = #selector(themeChanged(_:))

            let item = NSToolbarItem(itemIdentifier: .themeSelector)
            item.view = popup
            return item
        }

        if itemIdentifier == .metaInfo {
            titleLabel.font = NSFont.boldSystemFont(ofSize: 14)
            titleLabel.textColor = .labelColor
            [createdAtLabel, updatedAtLabel].forEach {
                $0.font = NSFont.systemFont(ofSize: 12)
                $0.textColor = .secondaryLabelColor
            }

            let stack = NSStackView(views: [titleLabel, createdAtLabel, updatedAtLabel])
            stack.orientation = .horizontal
            stack.spacing = 16
            stack.alignment = .centerY

            let item = NSToolbarItem(itemIdentifier: .metaInfo)
            item.view = stack
            return item
        }

        return nil
    }
    
    func updateToolbar(for document: Document) {
        titleLabel.stringValue = "\(document.title)"
        createdAtLabel.stringValue = "createdAt: \(format(date: document.createdAt))"
        updatedAtLabel.stringValue = "lastModifiedAt: \(format(date: document.updatedAt))"
    }

    private func format(date: Date?) -> String {
        guard let date else { return "-" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func extractOutlineItems(from markDown: String) -> [OutlineItem] {
        let lines = markDown.components(separatedBy: .newlines)
        var outlineItems: [OutlineItem] = []
        
        var location = 0
        for line in lines {
            let range = NSRange(location: location, length: (line as NSString).length)
            location += range.length + 1 // +1 for newline
            
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("#") else { continue }
            
            let level = trimmed.prefix { $0 == "#" }.count
            let title = trimmed.drop(while: { $0 == "#" }).trimmingCharacters(in: .whitespaces)
            
            outlineItems.append(OutlineItem(title: title, level: level, range: range))
        }
        
        return outlineItems
    }
            
}

extension ViewController: MarkDownEditTextViewDelegate {
    func textView(_ textView: MarkDownEditTextView, didLoadMarkdown text: String) {
        viewModel.markDownText.accept(text)
    }
}

extension ViewController: NSTableViewDelegate {
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0 && selectedRow < listViewModel.documents.value.count else { return }
        let doc = listViewModel.documents.value[selectedRow]
        selectedDocument = doc
        textView.string = doc.content
        viewModel.markDownText.accept(doc.content)
    }
}

extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return listViewModel.documents.value.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let doc = listViewModel.documents.value[row]
        let identifier = NSUserInterfaceItemIdentifier("TitleColumn")

        let cell = NSTableCellView()
        let textField = NSTextField(string: doc.title)
        textField.isEditable = true
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.delegate = self
        textField.tag = row // 編集時に参照用

        cell.identifier = identifier
        cell.textField = textField
        cell.addSubview(textField)

        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -8),
            textField.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])
        
        return cell
    }
}

extension ViewController: DocumentListTableViewDeletionDelegate {
    
    func documentListTableView(_ tableView: DocumentListTableView, didDeleteDocumentAt indexPath: IndexPath) {
        let row = indexPath.item
        guard row >= 0, row < listViewModel.documents.value.count else { return }

        let doc = listViewModel.documents.value[row]

        let alert = NSAlert()
        alert.messageText = "本当に削除しますか？"
        alert.informativeText = "「\(doc.title)」を削除します。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "削除")
        alert.addButton(withTitle: "キャンセル")

        if alert.runModal() == .alertFirstButtonReturn {
            listViewModel.deleteDocument(doc)
        }
    }
}

extension ViewController: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let field = obj.object as? NSTextField else { return }
        let row = field.tag
        guard row >= 0, row < listViewModel.documents.value.count else { return }

        let doc = listViewModel.documents.value[row]
        let newTitle = field.stringValue

        listViewModel.updateDocumentTitle(document: doc, newTitle: newTitle)
    }
}
        
extension NSToolbarItem.Identifier {
    static let themeSelector = NSToolbarItem.Identifier("ThemeSelector")
    static let metaInfo = NSToolbarItem.Identifier("MetaInfo")
}
