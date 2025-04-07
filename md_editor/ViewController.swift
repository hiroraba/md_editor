//
//  ViewController.swift
//  md_editor
//
//  Created by 松尾宏規 on 2025/04/07.
//

import Cocoa
import WebKit
import RxSwift
import RxCocoa

class ViewController: NSViewController, WKNavigationDelegate, NSToolbarDelegate {
    
    private let textView = NSTextView()
    private let webView = WKWebView()
    
    private let viewModel = EditorViewModel()
    private let disposeBag = DisposeBag()
    
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
        paragraphStyle.lineSpacing = 10  // Adjusted to match ruler spacing
        textView.defaultParagraphStyle = paragraphStyle
        textView.typingAttributes[.paragraphStyle] = paragraphStyle
        
        leftScrollView.documentView = textView
        
        leftScrollView.rulersVisible = true

        let lineNumberRulerView = LineNumberRulerView(textView: textView)
        leftScrollView.verticalRulerView = lineNumberRulerView
        lineNumberRulerView.needsDisplay = true

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
        
        self.view = splitView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.rx.notification(
            NSText.didChangeNotification,
            object: textView
        ).compactMap {[weak self] _ in
            return self?.textView.string
        }.bind(to: viewModel.markDownText)
            .disposed(by: disposeBag)
        
        viewModel.htmlText.observe(on: MainScheduler.instance).subscribe(onNext: { [weak self] html in
            self?.webView.loadHTMLString(html, baseURL: nil)
        }).disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(NSText.didChangeNotification, object: textView)
            .subscribe(onNext: { [weak self] _ in
                (self?.textView.enclosingScrollView?.verticalRulerView as? LineNumberRulerView)?.needsDisplay = true
            })
            .disposed(by: disposeBag)
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
        return [.flexibleSpace, .themeSelector]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.flexibleSpace, .themeSelector]
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
            item.label = "Theme"
            item.paletteLabel = "Theme"
            return item
        }
        return nil
    }
}

extension NSToolbarItem.Identifier {
    static let themeSelector = NSToolbarItem.Identifier("ThemeSelector")
}
