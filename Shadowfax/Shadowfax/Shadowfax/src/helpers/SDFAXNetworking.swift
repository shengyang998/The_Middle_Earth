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
//                self.imladrisService = SDFAXImladrisServiceClient(address: GlobalConstants.imladrisAddress)
                let certURL = Bundle.main.url(forResource: "imladris", withExtension: "crt")!
                let cert = try! String(contentsOf: certURL)
                self.imladrisService = SDFAXImladrisServiceClient(address: GlobalConstants.imladrisAddress, certificates: cert)
                dispatchGroup?.leave()
            }
            return
        }
    }

    func prepareUserAccountService(_ dispatchGroup: DispatchGroup?) {
        guard let _ = self.userAccountService else {
            dispatchGroup?.enter()
            utilityDispatchQueue.async { [unowned self] in
//                self.userAccountService = SDFAXUserAccountServiceClient(address: GlobalConstants.gondorAddress)
                let certURL = Bundle.main.url(forResource: "gondor", withExtension: "crt")!
                let cert = try! String(contentsOf: certURL)
                self.userAccountService = SDFAXUserAccountServiceClient(address: GlobalConstants.gondorAddress, certificates: cert)
                dispatchGroup?.leave()
            }
            return
        }
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
                completion(HostAddress().set(ip: reply.distIp, port: Int(reply.distPort)!))
            } else {
                Logger.error(message: "Error: \(result)")
            }
        })
    }

    func getUUID(phone: String, completion: @escaping ((_ uuid: String) -> Void)) {
        let dispatchGroup = DispatchGroup()
        prepareUserAccountService(dispatchGroup)
        var request = SDFAXGetUserUUIDRequest()
        request.uuid = GlobalConstants.selfUUID
        request.token = GlobalConstants.selfToken
        dispatchGroup.wait()
        try! userAccountService?.getUserUUID(request, completion: { (reply, result) in
            Logger.info(message: "gRPC GetUserUUID get reply: \(String(describing: reply)), \(String(describing: result))")
            if let reply = reply {
                completion(reply.distUuid)
            } else {
                Logger.warning(message: "User with PhoneNumber: \(phone)'s UUID not found")
            }
        })
    }

    func sendTo(phone: String, message: String, id: UInt64) {
        getUUID(phone: phone) { [unowned self] (uuid) in
            self.getAddress(uuid: uuid, { [unowned self] (address) in // gRPC method called here
                self.chatNetwork.sendTo(address: address, msg: message, id: id) // socket method called here
                // self.sendTo(address: address)
            })
        }
    }

    private func signal() {
        Logger.info(message: "Sending Signal...")
        let dispatchGroup = DispatchGroup()
        prepareImladrisService(dispatchGroup)
        var request = SDFAXSignalRequest()
        request.signal = 1
        request.uuid = GlobalConstants.selfUUID
        try! imladrisService?.signal(request, completion: { (reply, result) in
            Logger.info(message: ("Get Signal Reply: \(String(describing: reply)), \(String(describing: result))"))
        })
    }

    func startHearBeats() {
        Timer.init(fire: Date(), interval: GlobalConstants.standardHearBeatsTimeInterval, repeats: true) { [unowned self] (_) in
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
