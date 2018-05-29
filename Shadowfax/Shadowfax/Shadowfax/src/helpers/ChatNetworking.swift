//
//  ChatNetworking.swift
//  Shadowfax
//
//  Created by Ysy on 2018/5/29.
//  Copyright © 2018年 Ysy. All rights reserved.
//

import Foundation
import SwiftyRSA
import CryptoSwift
import CocoaAsyncSocket

class ChatNetworking: NSObject {

    // MARK: variables
    lazy var keyPair = SwiftyRSA.generateRSAKeyPair(sizeInBits: 2048)
    var pubKey: PublicKey { return keyPair.publicKey }
    var priKey: PrivateKey { return keyPair.privateKey }

    lazy var queue = DispatchQueue(label: "self.ysy.Shadowfax.\(self)", qos: .utility)

    lazy var handShakeSocket: GCDAsyncSocket = GCDAsyncSocket(delegate: self, delegateQueue: self.queue)
    lazy var udpSocket: GCDAsyncUdpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: self.queue)
    lazy var chatSocket: GCDAsyncSocket = GCDAsyncSocket(delegate: ChatSocketDelegate(), delegateQueue: self.queue)

    lazy var emptyUDPRequest: SDFAXEmptyRequestForUDP = {
        var t = SDFAXEmptyRequestForUDP();
        t.nothing = 3;
        return t;
    }()

    var AESKey: ClearMessage?
}

extension ChatNetworking {

    // MARK: prepare methods
    func prepareSocket(toHost host: String, onPort port: UInt16) {
        prepareUdpSocket(toHost: host, onPort: port)
        do { try self.handShakeSocket.connect(toHost: host, onPort: port) }
        catch { Logger.error(message: "Cannot connect to \(host):\(port)") }
    }

    func prepareUdpSocket(toHost host: String, onPort port: UInt16) {
        if !udpSocket.isConnected() {
            do {
                try udpSocket.connect(toHost: host, onPort: port)
                try udpSocket.send(emptyUDPRequest.serializedData(), withTimeout: GlobalConstants.standardTimeout, tag: 1)
                udpSocket.closeAfterSending()
            }
            catch { Logger.error(message: "\(error)") }
            return
        }
    }

    func prepareChatSocket(address: HostAddress) {
        if self.handShakeSocket.isConnected {
            self.handShakeSocket.disconnectAfterWriting()
        }
        do {
            let host = address.ip
            let port = address.port
            try self.chatSocket.connect(toHost: host, onPort: port, withTimeout: GlobalConstants.standardTimeout)
        }
        catch { Logger.error(message: "\(error)") }
    }

    // MARK: start listening methods
    func startHandShakeListening(onPort port: UInt16) {
        if self.chatSocket.isConnected {
            self.chatSocket.disconnectAfterWriting()
        }
        if let _ = try? self.handShakeSocket.accept(onPort: port) {
            Logger.info(message: "Scoket is listening on port: \(port)")
        } else {
            Logger.warning(message: "Port: \(port) has been occupied.")
        }
    }

    func startChatSocketListening(onPort port: UInt16) {
        if let _ = try? self.chatSocket.accept(onPort: port) {
            Logger.info(message: "Scoket is listening on port: \(port)")
        } else {
            Logger.warning(message: "Port: \(port) has been occupied.")
        }
    }

    // MAKR: send or make hand shake methods
    func makeSecureHandShake(to address: HostAddress) -> Bool {
        // TODO
        // 1. alice.pub                            ->   bob
        // 2. alice                                <-   crypto(bob.AESKey, with: alice.pub) // FIXME: Should not. Because the `bob.AESKey` is unable to verify.
        // 3. crypto(alice.AESKey, with: bob.pub)  ->   bob
        prepareSocket(toHost: address.ip, onPort: address.port)
        sendPUB(to: address)
        // wait for delegate to handle bob's AESKey
        return false
    }

    func sendPUB(to address: HostAddress) {
        let pub = try! self.pubKey.data()
        self.handShakeSocket.write(pub, withTimeout: 30, tag: 2)
    }

    func sendTo(address: HostAddress, msg: String) {
        if self.makeSecureHandShake(to: address) == true {
            
        } else {
            Logger.warning(message: "The line is not secured!")
        }
    }

}

extension ChatNetworking: GCDAsyncSocketDelegate {

    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        Logger.info(message: "did read data with tag: \(tag)")
        Logger.info(message: "and data: \(String(describing: String(data: data, encoding: .utf8)))")
        let encrypted = EncryptedMessage(data: data)
        do {
            let t = try encrypted.decrypted(with: self.priKey, padding: Padding.PKCS1)
            self.AESKey = t
            Logger.info(message: "decrypted data: \(t)")
        }
        catch { Logger.error(message: "Cannot decrypt the message") }
    }

    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        Logger.info(message: "did disconnect with error: \(String(describing: err))")
    }

    func socket(_ sock: GCDAsyncSocket, didConnectTo url: URL) {
        Logger.info(message: "did connect to: \(url)")
    }

    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        Logger.info(message: "didWriteDataWithTag: \(tag)")
    }

}

extension ChatNetworking: GCDAsyncUdpSocketDelegate {

    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        Logger.info(message: "UDP didSendDataWith Tag: \(tag)")
    }

    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        Logger.warning(message: "UDP didNotSendDataWith Tag: \(tag)")
    }
}

class ChatSocketDelegate: NSObject, GCDAsyncSocketDelegate {

    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        Logger.info(message: "did read data with tag: \(tag)")
        Logger.info(message: "and data: \(String(describing: String(data: data, encoding: .utf8)))")
        
    }

    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        Logger.info(message: "did disconnect with error: \(String(describing: err))")
    }

    func socket(_ sock: GCDAsyncSocket, didConnectTo url: URL) {
        Logger.info(message: "did connect to: \(url)")
    }

    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        Logger.info(message: "didWriteDataWithTag: \(tag)")
    }

}















