//
//  SDFAXNetworking.swift
//  Shadowfax
//
//  Created by Ysy on 2018/5/27.
//  Copyright © 2018年 Ysy. All rights reserved.
//

import Foundation
import SwiftGRPC

class SDFAXNetworking {

    var imladrisService: SDFAXImladrisServiceClient?

    typealias UserUUID = String

    lazy var utilityDispatchQueue = DispatchQueue(label: "SDFAXNetworkingDispatchQueue", qos: DispatchQoS.utility, attributes: DispatchQueue.Attributes.concurrent)

    func prepareImladrisService(_ dispatchGroup: DispatchGroup?) {
        guard let _ = self.imladrisService else {
            dispatchGroup?.enter()
            utilityDispatchQueue.async { [unowned self] in
                self.imladrisService = SDFAXImladrisServiceClient(address: GlobalConstants.imladrisAddress)
                let certURL = Bundle.main.url(forResource: "imladris", withExtension: "crt")!
                let cert = try! String(contentsOf: certURL)
                self.imladrisService = SDFAXImladrisServiceClient(address: GlobalConstants.imladrisAddress, certificates: cert)
                dispatchGroup?.leave()
            }
            return
        }
    }

    func sendTo(uuid: UserUUID, message: String) {
        let dispatchGroup = DispatchGroup()
        prepareImladrisService(dispatchGroup)
        var request = SDFAXSendToRequest()
        request.distUuid = uuid
        request.sourceUuid = GlobalConstants.selfUUID
        dispatchGroup.wait()
        try! imladrisService?.sendTo(request, completion: { (reply, result) in
            Logger.info(message: "SendTo: \(String(describing: reply)), \(String(describing: result))")
        })
    }

}
