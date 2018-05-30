//
//  GlobalConstants.swift
//  Shadowfax
//
//  Created by Ysy on 2018/5/26.
//  Copyright © 2018年 Ysy. All rights reserved.
//

import Foundation
import UIKit

struct GlobalConstants {

    // Constants
    static let databaseVersion: UInt64 = 1
    static let standardHearBeatsTimeInterval = TimeInterval(150)
    static let standardTimeout = TimeInterval(30)
    static let InitialVector: Array<UInt8> = Array("FUGCdssIiiusts".utf8)

    static let isLoginKey = "is login key"
    static var isLogin: Bool {
        get { return UserDefaults.standard.bool(forKey: isLoginKey) }
        set { set(newValue, forKey: isLoginKey) }
    }

    static let uuidKey = "UUID Key For This User"
    static var selfUUID: String {
        get {
            guard let res = UserDefaults.standard.string(forKey: uuidKey) else {
                Logger.warning(message: "User's UUID not set. Using `default` instead.")
                return "default"
            }
            return res
        }
        set { set(newValue, forKey: uuidKey) }
    }

    static let tokenKey = "Token for This User"
    static var selfToken: String {
        get {
            guard let res = UserDefaults.standard.string(forKey: tokenKey) else {
                Logger.warning(message: "User's Token not set. Using `default` instead.")
                return "default"
            }
            return res
        }
        set { set(newValue, forKey: tokenKey) }
    }

    static let imladrisIpKey = "The IP of imladris server"
    static var imladrisIp: String {
        get { return UserDefaults.standard.string(forKey: imladrisIpKey) ?? "150.109.40.31" }
        set { set(newValue, forKey: imladrisIpKey) }
    }
    static let imladrisPortKey = "The Port of imladris server"
    static var imladrisPort: String {
        get { return UserDefaults.standard.string(forKey: imladrisPortKey) ?? "5010" }
        set { set(newValue, forKey: imladrisPortKey) }
    }
    static let imladrisAddressKey = "The Address of imladris server"
    static var imladrisAddress: String {
        get { return imladrisIp + ":" + imladrisPort }
    }

    static let gondorIpKey = "The IP of imladris server"
    static var gondorIp: String {
        get { return UserDefaults.standard.string(forKey: gondorIpKey) ?? "150.109.40.31" }
        set { set(newValue, forKey: gondorIpKey) }
    }
    static let gondorPortKey = "The Port of imladris server"
    static var gondorPort: String {
        get { return UserDefaults.standard.string(forKey: gondorPortKey) ?? "5000" }
        set { set(newValue, forKey: gondorPortKey) }
    }
    static let gondorAddressKey = "The Address of imladris server"
    static var gondorAddress: String {
        get { return gondorIp + ":" + gondorPort }
    }


}

extension GlobalConstants {

    // Functions
    static func set(_ value: Any? , forKey key: String) {
        UserDefaults.setValue(value, forKey: key)
    }

}

extension Array {
    func randomItem() -> Element {
        let randomIndex = Int(arc4random_uniform(UInt32(self.count)))
        return self[randomIndex]
    }
}

enum TypeOfImage: String {
    case png = ".png"
    case jpg = ".jpg"
}

extension UIImage {

    func writeToImages(imageName: String, uuid: String, chatid: String, typeOfImage type: TypeOfImage = .jpg) {
        let imagesDir = URL.getDirectory(dirName: "images", for: uuid, chatID: chatid)
        let imageFilePath = imagesDir.appendingPathComponent("\(imageName)\(type.rawValue)", isDirectory: false)
        self.writeToDocument(filePath: imageFilePath, typeOfImage: type)
    }

    func writeToAvatar(imageName: String, uuid: String, typeOfImage: TypeOfImage = .png) {
        let avatarsDir = URL.getDirectory(dirName: "avatars", for: uuid)
        let avatarFilePath = avatarsDir.appendingPathComponent("\(imageName)\(typeOfImage.rawValue)", isDirectory: false)
        self.writeToDocument(filePath: avatarFilePath, typeOfImage: typeOfImage)
    }

    func writeToDocument(filePath: URL, typeOfImage type: TypeOfImage = .png) {
        do {
            switch type {
            case .png:
                try self.wxCompressedPNGRepresentation().write(to: filePath)
            case .jpg:
                try self.wxCompressedJPEGRepresentation().write(to: filePath)
            }
        } catch {
            Logger.error(message: "Write \(type) to \(filePath) failed.")
        }
    }

}

extension URL {

    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths.first!
    }

    static func createDirectory(at path: URL) -> Bool {
        do{
            try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
            return true
        } catch {
            Logger.error(message: "Error: \(error)")
            return false
        }
    }

    static func getDirectory(dirName: String, for uuid: String, chatID: String? = nil) -> URL {
        var theDir = URL.getDocumentsDirectory().appendingPathComponent(uuid, isDirectory: true)
        if let chatid = chatID {
            theDir.appendPathComponent(chatid, isDirectory: true)
        }
        theDir.appendPathComponent(dirName, isDirectory: true)
        let _ = createDirectory(at: theDir)
        return theDir
    }

    static func getDirectory(at pathComponents: [String]) -> URL {
        var path: URL = getDocumentsDirectory()
        for i in pathComponents {
            path.appendPathComponent(i, isDirectory: true)
        }
        let _ = createDirectory(at: path)
        return path
    }

}
