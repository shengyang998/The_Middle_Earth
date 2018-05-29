////
////  SDFAXServer.swift
////  Shadowfax
////
////  Created by Ysy on 2018/5/28.
////  Copyright © 2018年 Ysy. All rights reserved.
////
//
//import Foundation
//import CocoaAsyncSocket
//import SwiftProtobuf
//
//class SDFAXServer : NSObject {
//
//    private static func randomValidPort() -> UInt16 {
//        let minPort = UInt32(1024)
//        let maxPort = UInt32(UINT16_MAX)
//        let value = maxPort - minPort + 1
//        return UInt16(minPort + arc4random_uniform(value))
//    }
//
//    typealias Callback = Optional<() -> Void>
//
//    open var onAccept: Callback
//    open var onDisconnect: Callback
//
//    private var port: UInt16 = SDFAXServer.randomValidPort()
//    let queue = DispatchQueue(label: "com.asyncSocket.\(self)", qos: .utility)
//
//    let socket: GCDAsyncSocket
//
//    var lastAcceptedSocket: SDFAXClient? = nil
//
//    override init() {
//        self.socket = GCDAsyncSocket()
//        super.init()
//
//        self.socket.delegate = self
//        self.socket.delegateQueue = self.queue
//    }
//
//}
//
//extension SDFAXServer {
//
//    func start() {
//        if let _ = try? self.socket.accept(onPort: self.port) {
//            Logger.info(message: "Scoket is listening on port: \(self.port)")
//        } else {
//            Logger.warning(message: "Port: \(self.port) has been occupied. Will try again...")
//            self.port = SDFAXServer.randomValidPort()
//            if let _ = try? self.socket.accept(onPort: self.port) {
//                Logger.info(message: "Scoket is listening on port: \(self.port)")
//            } else {
//                Logger.warning(message: "Port: \(self.port) has been occupied. Will dismiss...")
//            }
//        }
//    }
//
//}
//
//extension SDFAXServer: GCDAsyncSocketDelegate {
//
//    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
//        Logger.info(message: "serverDidAccecptNewSocket")
//
//        self.onAccept?()
//    }
//
//    func socket(_ sock: GCDAsyncSocket, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
//        Logger.info(message: "serverDidReceiveTrust: \(trust)")
//        
//    }
//
//    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
//        Logger.info(message: "serverDidReadDataWithTag: \(tag)")
//        
//    }
//
//    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
//        Logger.info(message: "serverDidDisconnect")
//        self.onDisconnect?()
//    }
//
//}
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
