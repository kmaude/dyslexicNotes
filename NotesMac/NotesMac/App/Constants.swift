import Foundation

enum Constants {
    static let appName = "Notes"
    static let bundleBaseFolderName = "Notes"
    static let appSupportFolderName = "Notes"

    static let defaultChunkSeconds: Int = 10
    static let autosplitMinutes: Int = 50
    static let markerPreSeconds: Double = 10
    static let markerPostSeconds: Double = 15

    static let lowDiskWarningThresholdBytes: Int64 = 2 * 1024 * 1024 * 1024
    static let lowBatteryWarningThresholdPercent: Int = 20

    static let defaultHighlightHex = "#CDE9FF"

    static let classColorPaletteHex: [String] = [
        "#4A90E2","#50E3C2","#7ED321","#F5A623","#BD10E0","#9013FE","#D0021B","#F8E71C",
        "#8B572A","#417505","#B8E986","#9B9B9B","#4A4A4A","#00AEEF","#FF6F61","#6B7C93"
    ]
}
