import Foundation

class FilePath {
    static let packageName = "org.sagernet.sfi"
    static let groupName = "group.\(packageName)"

    static let sharedDirectory: URL! = FileManager().containerURL(forSecurityApplicationGroupIdentifier: groupName)

    static let cacheDirectory = sharedDirectory
        .appendingPathComponent("Library", isDirectory: true)
        .appendingPathComponent("Caches", isDirectory: true)

    static let workingDirectory = cacheDirectory.appendingPathComponent("Working", isDirectory: true)

    static let iCloudDirectory = FileManager.default.url(forUbiquityContainerIdentifier: nil)!.appendingPathComponent("Documents", isDirectory: true)
}

extension URL {
    var fileName: String {
        var path = relativePath
        if let index = path.lastIndex(of: "/") {
            path = String(path[path.index(index, offsetBy: 1)...])
        }
        return path
    }
}

extension URL {
    func formattedSize() throws -> String? {
        guard let urls = FileManager.default.enumerator(at: self, includingPropertiesForKeys: nil)?.allObjects as? [URL] else {
            return nil
        }
        let size = try urls.lazy.reduce(0) {
            try ($1.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize ?? 0) + $0
        }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        guard let byteCount = formatter.string(for: size) else {
            return nil
        }
        return byteCount
    }
}
