//
//  AppDelegate.swift
//  md_editor
//
//  Created by matsuohiroki on 2025/04/07.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let nioServer = NioSearchServer()
        DispatchQueue.global().async {
            try? nioServer.start()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {}

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
