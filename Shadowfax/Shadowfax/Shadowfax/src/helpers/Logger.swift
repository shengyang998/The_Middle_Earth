//
//  Logger.swift
//  Shadowfax
//
//  Created by Ysy on 2018/5/26.
//  Copyright © 2018年 Ysy. All rights reserved.
//

import Foundation

struct EventType: Comparable, Equatable {

    let desc: String
    let level: Int

    public static func == (lhs: EventType, rhs: EventType) -> Bool { return lhs.level == rhs.level }
    public static func < (lhs: EventType, rhs: EventType) -> Bool { return lhs.level < rhs.level }
    public static func <= (lhs: EventType, rhs: EventType) -> Bool { return !(lhs > rhs) }
    public static func >= (lhs: EventType, rhs: EventType) -> Bool { return !(lhs < rhs) }
    public static func > (lhs: EventType, rhs: EventType) -> Bool { return !(lhs < rhs) && !(lhs == rhs) }

}

struct LogEvent {

    static let debug = EventType(desc: "[💬]", level: 0)
    static let info = EventType(desc: "[ℹ️]", level: 1)
    static let warning = EventType(desc: "[⚠️]", level: 2)
    static let error = EventType(desc: "[‼️]", level: 3)
    static let severe = EventType(desc: "[🔥]", level: 4)

}

class Logger {

    static var level: EventType = LogEvent.debug

    static var dateFormat = "yyyy-MM-dd hh:mm:ssSSS"

    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        return formatter
    }

    @inline(__always)
    class func debug(message: String) {
        #if DEBUG
        if level >= LogEvent.debug {
            print("\(Date().toString()) \(LogEvent.debug.desc)[\(sourceFileName(filePath: #file))]:\n\(#line) \(#column) \(#function) -> \(message)")
        }
        #endif
    }

    @inline(__always)
    class func info(message: String) {
        #if DEBUG
        if level >= LogEvent.info {
            print("\(Date().toString()) \(LogEvent.info.desc)[\(sourceFileName(filePath: #file))]:\n\(#line) \(#column) \(#function) -> \(message)")
        }
        #endif
    }

    @inline(__always)
    class func warning(message: String) {
        #if DEBUG
        if level >= LogEvent.warning {
            print("\(Date().toString()) \(LogEvent.warning.desc)[\(sourceFileName(filePath: #file))]:\n\(#line) \(#column) \(#function) -> \(message)")
        }
        #endif
    }

    @inline(__always)
    class func error(message: String) {
        #if DEBUG
        if level >= LogEvent.error {
            print("\(Date().toString()) \(LogEvent.error.desc)[\(sourceFileName(filePath: #file))]:\n\(#line) \(#column) \(#function) -> \(message)")
        }
        #endif
    }

    @inline(__always)
    class func severe(message: String) {
        #if DEBUG
        if level >= LogEvent.severe {
            print("\(Date().toString()) \(LogEvent.severe.desc)[\(sourceFileName(filePath: #file))]:\n\(#line) \(#column) \(#function) -> \(message)")
        }
        #endif
    }

    @inline(__always)
    class func log(message: String,
                   event: EventType = LogEvent.info,
                   fileName: String = #file,
                   line: Int = #line,
                   column: Int = #column,
                   funcName: String = #function)
    {
        #if DEBUG
        if level >= event {
            print("\(Date().toString()) \(event.desc)[\(sourceFileName(filePath: fileName))]:\n\(line) \(column) \(funcName) -> \(message)")
        }
        #endif
    }

    private class func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.isEmpty ? "" : components.last!
    }

}

fileprivate extension Date {
    func toString() -> String {
        return Logger.dateFormatter.string(from: self as Date)
    }
}
