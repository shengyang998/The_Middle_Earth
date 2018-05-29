////
////  SDFAXClient.swift
////  Shadowfax
////
////  Created by Ysy on 2018/5/28.
////  Copyright © 2018年 Ysy. All rights reserved.
////
//
//import Foundation
//
//class SDFAXClient : NSObject {
//
//    /**
//     *  Identifies what end of the socket the instance represents.
//     */
//    enum Role {
//        case server, client
//    }
//
//    lazy var queue: DispatchQueue = { [unowned self] in
//        return DispatchQueue(label: "com.asyncSocket.\(self)", qos: DispatchQoS.utility)
//        }()
//
//    let socket: GCDAsyncSocket
//
//    // MARK: Convience callbacks
//    typealias Callback = Optional<() -> Void>
//
//    var onConnect: Callback
//    var onSecure: Callback
//    var onRead: Callback
//    var onWrite: Callback
//    var onDisconnect: Callback
//
//    // MARK: Counters
//    var bytesRead = 0
//    var bytesWritten = 0
//
//    override convenience init() {
//        self.init(socket: GCDAsyncSocket())
//    }
//
//    init(socket: GCDAsyncSocket) {
//        self.socket = socket
//        super.init()
//
//        self.socket.delegate = self
//        self.socket.delegateQueue = self.queue
//    }
//
//}
//
//// MARK: Synchronous API
//extension SDFAXClient {
//
//}
//
//// MARK: GCDAsyncSocketDelegate
//extension SDFAXClient: GCDAsyncSocketDelegate {
//
//    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
//        Logger.info(message: "clientDidConnectToHost: \(host), port: \(port)")
//        self.onConnect?()
//    }
//
////
////    func socketDidSecure(_ sock: GCDAsyncSocket) {
////        Logger.info(message: "socketDidSecure")
////        self.onSecure?()
////    }
//
//    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
//        Logger.info(message: "clientDidWriteDataWithTag: \(tag)")
//        self.onWrite?()
//    }
//
//    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
//        Logger.info(message: "clientDidReadDataWithTag: \(tag)")
//        self.bytesRead += data.count
//        self.onRead?()
//    }
//
//    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
//        Logger.info(message: "clientDidDisconnectWitError")
//        self.onDisconnect?()
//    }
//
//    func socket(_ sock: GCDAsyncSocket, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
//        Logger.info(message: "clientDidReceive trust: \(trust)")
//        completionHandler(true) // Trust all the things!!
//    }
//
//}
