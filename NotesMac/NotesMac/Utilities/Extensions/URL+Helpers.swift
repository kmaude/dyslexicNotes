import Foundation

extension URL {
    static var notesAppSupport: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent(Constants.appSupportFolderName, isDirectory: true)
    }

    static var notesDatabaseURL: URL {
        notesAppSupport.appendingPathComponent("notes.sqlite")
    }

    static var notesSettingsURL: URL {
        notesAppSupport.appendingPathComponent("settings.json")
    }

    static var notesModelsFolder: URL {
        notesAppSupport.appendingPathComponent("Models", isDirectory: true)
    }

    static var notesBundlesBase: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(Constants.bundleBaseFolderName, isDirectory: true)
    }
}
