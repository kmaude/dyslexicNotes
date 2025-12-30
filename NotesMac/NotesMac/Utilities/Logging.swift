import Foundation

enum Log {
    static func info(_ message: String) {
        #if DEBUG
        print("[Notes][INFO] " + message)
        #endif
    }

    static func error(_ message: String) {
        print("[Notes][ERROR] " + message)
    }
}
