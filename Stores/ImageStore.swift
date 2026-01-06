import Foundation
import UIKit

struct ImageStore {
    func save(image: UIImage, for date: Date, angle: PhotoAngle) throws -> URL {
        let base = try baseDirectory()
        let dayDir = base.appendingPathComponent(date.yyyyMMdd, isDirectory: true)
        try FileManager.default.createDirectory(at: dayDir, withIntermediateDirectories: true)

        let fileURL = dayDir.appendingPathComponent("\(angle.fileNameComponent).jpg")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }

        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw NSError(domain: "Akanuke", code: 1, userInfo: [NSLocalizedDescriptionKey: "JPEG変換に失敗しました"])
        }

        try data.write(to: fileURL, options: [.atomic])
        return fileURL
    }

    func loadImage(at path: String) -> UIImage? {
        UIImage(contentsOfFile: path)
    }

    private func baseDirectory() throws -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let dir = appSupport.appendingPathComponent("AkanukeLog/records", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
