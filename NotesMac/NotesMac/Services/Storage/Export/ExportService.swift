import Foundation
import AppKit
import UniformTypeIdentifiers

@MainActor
final class ExportService {
    enum Format {
        case rtf
        case docx
    }

    func exportText(_ text: String, suggestedName: String, format: Format) async {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = suggestedName + (format == .rtf ? ".rtf" : ".docx")
        panel.allowedContentTypes = format == .rtf ? [.rtf] : [UTType(filenameExtension: "docx") ?? .data]

        let resp = panel.runModal()
        guard resp == .OK, let url = panel.url else { return }

        do {
            switch format {
            case .rtf:
                try RTFExporter().export(text: text, to: url)
            case .docx:
                try DOCXExporter().export(text: text, to: url)
            }
        } catch {
            NSSound.beep()
        }
    }
}
