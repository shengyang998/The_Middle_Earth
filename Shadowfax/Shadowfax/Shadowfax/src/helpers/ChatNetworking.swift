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
import SwiftProtobuf

fileprivate enum ChatNetworkingTags: Int {
    case initiativeHandShakeHeaderTag = 100,
    initiativeHandShakeBodyTag,
    chatHeaderTag,
    chatBodyTag,
    chatRecvBodyTag,
    passiveHandShakeHeaderTag,
    passiveHandShakeBodyTag
}

// MARK: constants
let standardTimeout = GlobalConstants.standardTimeout
let headerByte: UInt = 8

// MARK: typealiases
typealias HeaderLength = UInt64

class ChatNetworking: NSObject {

    // MARK: variables
    lazy var keyPair = SwiftyRSA.generateRSAKeyPair(sizeInBits: 2048)
    var pubKey: PublicKey { return keyPair.publicKey }
    var priKey: PrivateKey { return keyPair.privateKey }
    var aes: AES? {
        do {
            return try AES(key: self.AESKey, blockMode: BlockMode.CTR(iv: self.iv), padding: .noPadding)
        } catch {
            Logger.severe(message: "Cannot construct AES instance with error: \(error)")
            return nil
        }
    }

    private lazy var queue = DispatchQueue(label: "self.ysy.Shadowfax.\(self)", qos: .utility)
    private lazy var dispatchGroup = DispatchGroup()

    private lazy var socket: GCDAsyncSocket = GCDAsyncSocket(delegate: self, delegateQueue: self.queue)
    private lazy var udpSocket: GCDAsyncUdpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: self.queue)

    private lazy var emptyUDPRequest: SDFAXEmptyRequestForUDP = {
        var t = SDFAXEmptyRequestForUDP();
        t.nothing = 3;
        return t;
    }()

    private lazy var AESKey: Array<UInt8> = try! HKDF(password: GlobalConstants.InitialVector).calculate()
    private lazy var iv: Array<UInt8> = try! HKDF(password: GlobalConstants.InitialVector).calculate()
    var isSecured: Bool = false

    override init() {
        super.init()
        self.startHandShakeListening(onPort: GlobalConstants.clientPort)
        self.passivelyMakeSecureHandShake()
    }
}

extension ChatNetworking {

    // MARK: prepare methods
    func prepareSocket(toHost host: String, onPort port: UInt16) {
        prepareUdpSocket(toHost: host, onPort: port)
        if !self.socket.isConnected {
            do { try self.socket.connect(toHost: host, onPort: port) }
            catch { Logger.error(message: "Cannot connect to \(host):\(port)") }
        }
    }

    func prepareUdpSocket(toHost host: String, onPort port: UInt16) {
        if !self.udpSocket.isConnected() {
            do {
                try udpSocket.connect(toHost: host, onPort: port)
                try udpSocket.send(emptyUDPRequest.serializedData(), withTimeout: standardTimeout, tag: 1)
                try udpSocket.send(emptyUDPRequest.serializedData(), withTimeout: standardTimeout, tag: 1)
                try udpSocket.send(emptyUDPRequest.serializedData(), withTimeout: standardTimeout, tag: 1)
                udpSocket.closeAfterSending()
            }
            catch { Logger.error(message: "\(error)") }
            return
        }
    }

    // MARK: start listening methods
    func startHandShakeListening(onPort port: UInt16) {
        if let _ = try? self.socket.accept(onPort: port) {
            Logger.info(message: "Scoket is listening on port: \(port)")
        } else {
            Logger.warning(message: "Port: \(port) has been occupied.")
        }
    }

    // MAKR: send or make hand shake methods
    private func initiativlyMakeSecureHandShake(to address: HostAddress) -> Bool {
        // MARK
        // 1. alice.pub                            ->   bob
        // 2. alice                                <-   crypto(bob.AESKey, with: alice.pub) // FIXME: Should not. Because the `bob.AESKey` is unable to verify.
        // 3. crypto(alice.AESKey, with: bob.pub)  ->   bob
        dispatchGroup.enter()
        prepareSocket(toHost: address.ip, onPort: address.port)
        if self.isSecured == false {
            sendPUB(to: address)
            self.socket.readData(toLength: headerByte, withTimeout: standardTimeout, tag: ChatNetworkingTags.initiativeHandShakeHeaderTag.rawValue)
        }
        // now delegate to handle bob's AESKey

        return true
    }

    // MARK: get or make hand shake passively
    func passivelyMakeSecureHandShake() {
        // 1. already accept on port 52013
        // 2. `did accept new socket` delegate handle rsa pub from bob
        if self.isSecured == false {
            self.socket.readData(toLength: headerByte, withTimeout: -1, tag: ChatNetworkingTags.passiveHandShakeHeaderTag.rawValue)
            Logger.info(message: "Waiting to read handshake header")
        } else {
            self.socket.readData(toLength: headerByte, withTimeout: -1, tag: ChatNetworkingTags.chatHeaderTag.rawValue)
            Logger.info(message: "Waiting for message header to come")
        }
    }

    func sendPUB(to address: HostAddress) {
        let pub = try! self.pubKey.data()
        let headerLength = Data(from: HeaderLength(pub.count))
        self.socket.write(headerLength, withTimeout: standardTimeout, tag: ChatNetworkingTags.initiativeHandShakeHeaderTag.rawValue)
        self.socket.write(pub, withTimeout: standardTimeout, tag: ChatNetworkingTags.initiativeHandShakeBodyTag.rawValue)
    }

    func sendTo(address: HostAddress, msg: String, id: UInt64) {
        self.initiativlyMakeSecureHandShake(to: address)
        dispatchGroup.wait()
        // MARK: aes(protobuf(msg))
        if self.isSecured {
            let protobufMsgSend = SDFAXmsgSend(id: id,
                                               payload: msg,
                                               time: Date().ticks)

            let encryptedData = self.encryptProtobufObject(obj: protobufMsgSend, aes: self.aes!)!
            Logger.debug(message: "Data Encrypted: \(encryptedData)")

            let bodyLength = encryptedData.count
            self.socket.write(Data(from: HeaderLength(bodyLength)), withTimeout: standardTimeout, tag: ChatNetworkingTags.chatHeaderTag.rawValue)
            self.socket.write(Data(from: encryptedData), withTimeout: standardTimeout, tag: ChatNetworkingTags.chatBodyTag.rawValue)
        } else {
            Logger.warning(message: "The line is not secured!")
        }
    }

    private func encryptProtobufObject(obj: SwiftProtobuf.Message, aes: AES) -> [UInt8]? {
        let aes = self.aes
        do {
            let data = try obj.serializedData()
            let encryptedData: [UInt8] = try aes!.encrypt(Array(data))
            return encryptedData
        }
        catch {
            Logger.error(message: "Parse Protobuf Objecti to Data Failed!")
            return nil
        }
    }

    func getAESKey(encryptedData data: Data) -> Array<UInt8>? {
        let encrypted = EncryptedMessage(data: data)
        do {
            // MARK: Don't know if this would work
            let t = try encrypted.decrypted(with: self.priKey, padding: Padding.PKCS1)
            Logger.debug(message: "decrypted data (AESKey): \(t)")
            return Array(t.data)
        }
        catch { Logger.severe(message: "Cannot decrypt the message"); return nil }
    }

    func getDecryptedMessage(encryptedData data: Data) -> SDFAXmsgSend? {
        // MARK: aes -> protobuf -> msg
        do {
            let aes = self.aes
            let decryptedByteStream = try aes!.decrypt(Array(data))
            let decryptedData = Data(decryptedByteStream)
            let msg = try SDFAXmsgSend(serializedData: decryptedData)
            Logger.debug(message: "Message Decrypted: \(msg.payload)")
            return msg
        } catch {
            Logger.severe(message: "Reading msg failed with error: \(error)")
            return nil
        }
    }

    func getDecryptedRecv(encryptedData data: Data) -> SDFAXmsgRecv? {
        do {
            if let aes = self.aes {
                let decryptedByteStream = try aes.decrypt(Array(data))
                let decryptedData = Data(decryptedByteStream)
                let recv = try SDFAXmsgRecv(serializedData: decryptedData)
                Logger.debug(message: "Recv Decrypted: msg \(recv.id) \(recv.isread ? "is read" : "is sent")")
                return recv
            } else {
                Logger.error(message: "Cannot init aes instance.")
                return nil
            }
        } catch {
            Logger.severe(message: "Reading recv failed with error: \(error)")
            return nil
        }
    }
}

extension ChatNetworking: GCDAsyncSocketDelegate {

    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        Logger.info(message: "did read data with tag: \(String(describing: ChatNetworkingTags(rawValue: tag)))")
        Logger.debug(message: "and data: \(String(describing: String(data: data, encoding: .utf8)))")

        switch tag {
        // MARK: hand shake header -> body length
        case ChatNetworkingTags.initiativeHandShakeHeaderTag.rawValue:
            let bodyLength = data.to(type: HeaderLength.self)
            sock.readData(toLength: UInt(bodyLength), withTimeout: standardTimeout, tag: ChatNetworkingTags.initiativeHandShakeBodyTag.rawValue)

        // MARK: hand shake body: rsa(AESKey)
        case ChatNetworkingTags.initiativeHandShakeBodyTag.rawValue:
            self.AESKey = getAESKey(encryptedData: data)!
            self.isSecured = true
            dispatchGroup.leave()

        // MARK: chat header : body length
        case ChatNetworkingTags.chatHeaderTag.rawValue:
            let signal: [UInt8] = Array(data)
            let bodyLength = data.toBodyLength()
            if signal[4] == 1 { // FIXME: This is ugly!
                socket.readData(toLength: bodyLength, withTimeout: standardTimeout, tag: ChatNetworkingTags.chatRecvBodyTag.rawValue)
            }
            else {
                socket.readData(toLength: bodyLength, withTimeout: standardTimeout, tag: ChatNetworkingTags.chatBodyTag.rawValue)
            }

        // MARK: chat msgSend : encrypted msgSend
        case ChatNetworkingTags.chatBodyTag.rawValue:
            let decryptedMessage = getDecryptedMessage(encryptedData: data)!
            // MARK: Realm invoke! DataSource invoke!
            var msg = Message.set(id: Int(decryptedMessage.id),
                              payload: decryptedMessage.payload,
                              time: Date(ticks: decryptedMessage.time),
                              type: Int(decryptedMessage.type))
            let db = DBConnection.db
            try! db.write {
                db.add(msg, update: false)
            }
            

        // MARK: chat msgRecv : encrypted msgRecv
        case ChatNetworkingTags.chatRecvBodyTag.rawValue:
            let decryptedRecv = getDecryptedRecv(encryptedData: data)!
            // MARK: Realm invoke! DataSource invoke!
            let db = DBConnection.db
            var msg = db.object(ofType: Message.self, forPrimaryKey: Int(decryptedRecv.id))!
            msg.isread = decryptedRecv.isread
            try! db.write {
                db.add(msg, update: true)
            }


        // MARK: passively handshake header
        case ChatNetworkingTags.passiveHandShakeHeaderTag.rawValue:
            let bodyLength = data.to(type: HeaderLength.self)
            sock.readData(toLength: UInt(bodyLength), withTimeout: standardTimeout, tag: ChatNetworkingTags.initiativeHandShakeBodyTag.rawValue)

        // MARK: passively body: pub
        case ChatNetworkingTags.passiveHandShakeBodyTag.rawValue:
            let pubKey = try! PublicKey(data: data)
            let clearAESKey = ClearMessage(data: Data(self.AESKey))
            let encryptedAESKey = try! clearAESKey.encrypted(with: pubKey, padding: Padding.PKCS1)
            let headerLength = UInt(encryptedAESKey.data.count)
            socket.write(Data(from: headerLength), withTimeout: standardTimeout, tag: ChatNetworkingTags.passiveHandShakeHeaderTag.rawValue)
            socket.write(encryptedAESKey.data, withTimeout: standardTimeout, tag: ChatNetworkingTags.passiveHandShakeBodyTag.rawValue)

        default:
            Logger.error(message: "This tag is not defined!")
        }
    }

    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        self.socket = newSocket
        self.passivelyMakeSecureHandShake()
    }

    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        Logger.info(message: "didWriteDataWithTag: \(ChatNetworkingTags(rawValue: tag))")
    }

    func socket(_ sock: GCDAsyncSocket, didConnectTo url: URL) {
        Logger.info(message: "did connect to: \(url)")
    }

    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        Logger.info(message: "did disconnect with error: \(String(describing: err))")
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

fileprivate extension Data {
    func toBodyLength() -> UInt {
        return UInt(self.to(type: UInt32.self))
    }

    func addRecvSignal() -> Data {
        return Data(from: (self.to(type: UInt64.self) + 0x100000000))
    }
}

fileprivate extension HeaderLength {

    func asRecvLength() -> UInt {
        return UInt(self + 0x100000000)
    }

}
