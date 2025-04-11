//
//  NioSearchServer.swift
//  md_editor
//
//  Created by 松尾宏規 on 2025/04/09.
//

import Foundation
import NIO
import NIOHTTP1
import RealmSwift

final class NioSearchServer {
    private let port: Int
    private var group: EventLoopGroup?

    init(port: Int = 5555) {
        self.port = port
    }

    func start() throws {
        group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

        let bootstrap = ServerBootstrap(group: group!)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline().flatMap {
                    channel.pipeline.addHandler(SearchRequestHandler())
                }
            }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)

        let channel = try bootstrap.bind(host: "127.0.0.1", port: port).wait()
        print("🚀 NioSearchServer running at http://127.0.0.1:\(port)")
        try channel.closeFuture.wait()
    }

    func shutdown() {
        try? group?.syncShutdownGracefully()
    }
}

final class SearchRequestHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    private var query: String?

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)

        switch reqPart {
        case .head(let head):
            if head.uri.starts(with: "/search"),
               let url = URLComponents(string: "http://localhost\(head.uri)"),
               let query = url.queryItems?.first(where: { $0.name == "q" })?.value {
                self.query = query
            }
        case .body:
            break
        case .end:
            let responseBody = makeResponseBody(query: query ?? "")
            var buffer = context.channel.allocator.buffer(capacity: responseBody.utf8.count)
            buffer.writeString(responseBody)

            var headers = HTTPHeaders()
            headers.add(name: "Content-Type", value: "application/json; charset=utf-8")
            headers.add(name: "Content-Length", value: "\(buffer.readableBytes)")

            let head = HTTPResponseHead(version: .init(major: 1, minor: 1), status: .ok, headers: headers)
            context.write(self.wrapOutboundOut(.head(head)), promise: nil)
            context.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
            context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
        }
    }

    private func makeResponseBody(query: String) -> String {
        let realm = try! Realm() // swiftlint:disable:this force_try
        let results = realm.objects(Document.self)
            .filter("title CONTAINS[c] %@ OR content CONTAINS[c] %@", query, query)
            .prefix(5)

        let jsonArray: [[String: String]] = results.map {
            [
                "id": $0.id.stringValue,
                "title": $0.title,
                "snippet": $0.content
            ]
        }

        let responseDict = ["results": jsonArray]
        let data = try! JSONSerialization.data(withJSONObject: responseDict, options: []) // swiftlint:disable:this force_try
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("Error: \(error.localizedDescription)")
        context.close(promise: nil)
    }
}
