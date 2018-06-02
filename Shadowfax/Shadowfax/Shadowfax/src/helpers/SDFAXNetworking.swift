//
//  SDFAXNetworking.swift
//  Shadowfax
//
//  Created by Ysy on 2018/5/27.
//  Copyright © 2018年 Ysy. All rights reserved.
//

import Foundation
import SwiftGRPC
import RealmSwift

class SDFAXNetworking {
    private init(){}

    static let sharedInstance = SDFAXNetworking()

    var imladrisService: SDFAXImladrisServiceClient?
    var userAccountService: SDFAXUserAccountServiceClient?

    lazy var utilityDispatchQueue = DispatchQueue(label: "SDFAXNetworkingDispatchQueue", qos: .utility, attributes: DispatchQueue.Attributes.concurrent)

    lazy var chatNetwork = ChatNetworking()

//    lazy var localServer = SDFAXServer()
//    lazy var localClient = SDFAXClient()

}

// MARK: Class Methods
extension SDFAXNetworking {

}

// MARK: Methods
extension SDFAXNetworking {

    func prepareImladrisService(_ dispatchGroup: DispatchGroup?) {
        guard let _ = self.imladrisService else {
            dispatchGroup?.enter()
            utilityDispatchQueue.async { [unowned self] in
                let certURL = Bundle.main.url(forResource: "imladris", withExtension: "crt")!
                let cert = try! String(contentsOf: certURL)
//                self.imladrisService = SDFAXImladrisServiceClient(address: GlobalConstants.imladrisAddress, certificates: cert)
                self.imladrisService = SDFAXImladrisServiceClient(address: GlobalConstants.imladrisAddress, secure: false)
                dispatchGroup?.leave()
            }
            return
        }
    }

    func prepareUserAccountService(_ dispatchGroup: DispatchGroup?) {
        guard let _ = self.userAccountService else {
            dispatchGroup?.enter()
            utilityDispatchQueue.async { [unowned self] in
                let certURL = Bundle.main.url(forResource: "gondor", withExtension: "crt")!
                let cert = try! String(contentsOf: certURL)
//                self.userAccountService = SDFAXUserAccountServiceClient(address: GlobalConstants.gondorAddress, certificates: cert)
                self.userAccountService = SDFAXUserAccountServiceClient(address: GlobalConstants.gondorAddress, secure: false)
                dispatchGroup?.leave()
            }
            return
        }
    }

    func signin(phone: String, validationCode: String, _ completion: @escaping (() -> Void)) {
        let dispatchGroup = DispatchGroup()
        prepareImladrisService(dispatchGroup)
        var request = SDFAXSigninRequest()
        request.phone = phone
        request.validationCode = validationCode
        dispatchGroup.wait()
        try! imladrisService?.signin(request, completion: { (reply, result) in
            if let reply = reply {
                Logger.debug(message: "gRPC Signin get reply: \(String(describing: reply)), \(String(describing: result))")
            } else {
                Logger.debug(message: "gRPC Signin result: \(result)")
            }
        })
    }

    func getAddress(uuid: String, _ completion: @escaping ((HostAddress) -> Void)) {
        let dispatchGroup = DispatchGroup()
        prepareImladrisService(dispatchGroup)
        var request = SDFAXSendToRequest()
        request.distUuid = uuid
        request.sourceUuid = GlobalConstants.selfUUID
        dispatchGroup.wait()
        try! imladrisService?.sendTo(request, completion: { (reply, result) in
            Logger.info(message: "gRPC SendTo get reply: \(String(describing: reply)), \(String(describing: result))")
            if let reply = reply {
                if reply.statusCode == 200 {
                    completion(HostAddress().set(ip: reply.distIp, port: Int(reply.distPort)!))
                } else {
                    Logger.error(message: "Error with Error Code: \(reply.statusCode)_")
                }
            } else {
                Logger.error(message: "gRPC SendTo result: \(result)")
            }
        })
    }

//    func getUUID(phone: String, _ completion: @escaping ((_ uuid: String) -> Void)) {
//        let dispatchGroup = DispatchGroup()
//        prepareUserAccountService(dispatchGroup)
//        var request = SDFAXGetUserUUIDRequest()
//        request.uuid = GlobalConstants.selfUUID
//        request.token = GlobalConstants.selfToken
//        dispatchGroup.wait()
//        try! userAccountService?.getUserUUID(request, completion: { (reply, result) in
//            Logger.info(message: "gRPC GetUserUUID get reply: \(String(describing: reply)), \(String(describing: result))")
//            if let reply = reply {
//                completion(reply.uuid)
//            } else {
//                Logger.warning(message: "gRPC getUUID result: \(result)")
//            }
//        })
//    }

    func getUUID(phone: String, _ completion: @escaping ((_ uuid: String) -> Void)) {
        let dispatchGroup = DispatchGroup()
        prepareImladrisService(dispatchGroup)
        var request = SDFAXGetUUIDRequest()
        request.phone = phone
        dispatchGroup.wait()
        try! imladrisService?.getUUID(request, completion: { (reply, result) in
            if let reply = reply {
                Logger.debug(message: "Get GetUUID Reply: \(String(describing: reply))")
                completion(reply.uuid)
            } else {
                Logger.warning(message: "gRPC GetUUID result: \(result)")
            }
        })
    }

    func sendTo(uuid: String, message: String, id: UInt64) {
        self.getAddress(uuid: uuid) { (address) in
            self.chatNetwork.sendTo(address: address, msg: message, id: id)
        }
//        getUUID(phone: phone) { [unowned self] (uuid) in
//            self.getAddress(uuid: uuid, { [unowned self] (address) in // gRPC method called here
//                self.chatNetwork.sendTo(address: address, msg: message, id: id) // socket method called here
//                // TODO
//                // self.sendTo(address: address)
//            })
//        }
    }

    private func signal() {
        Logger.info(message: "Sending Signal...")
        let dispatchGroup = DispatchGroup()
        prepareImladrisService(dispatchGroup)
        var request = SDFAXSignalRequest()
        request.uuid = GlobalConstants.selfUUID
        try! imladrisService?.signal(request, completion: { [unowned self] (reply, result) in
            Logger.info(message: ("Get Signal Reply: \(String(describing: reply)), \(String(describing: result))"))
            if let reply = reply {
                if reply.statusCode == 200 {
                if reply.ip != "", reply.port != 0 {
                    Logger.info(message: "Signal Reply with host: \(reply.ip) : \(reply.port)")
                    self.chatNetwork.prepareUdpSocket(toHost: reply.ip, onPort: UInt16(reply.port))
                    }
                }
            } else {
                Logger.warning(message: "gRPC Signal result: \(result)")
            }
        })
    }

    func startHearBeats() {
        Timer.scheduledTimer(withTimeInterval: GlobalConstants.standardHearBeatsTimeInterval, repeats: true) { [unowned self] (_) in
            self.signal()
        }
    }

}

class HostAddress: Object {

    typealias Phone = String
    typealias Port = Int
    typealias IP = String

    @objc dynamic var ip: IP = ""
    @objc dynamic var port: Port = 0

    func set(ip: IP, port: Port) -> HostAddress {
        self.ip = ip
        self.port = port
        return self
    }
}
