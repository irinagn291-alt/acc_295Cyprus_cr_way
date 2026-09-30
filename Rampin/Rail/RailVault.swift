import Foundation

/// Role: Rail. Projects Rail to UserDefaults rmp.rail.v1 plus an atomic Application Support file. Views never touch this type.
actor RailVault {
    private let directory: URL
    private let suiteName: String?
    private let fileManager: FileManager

    init(
        directory: URL,
        suiteName: String? = nil,
        fileManager: FileManager = .default
    ) {
        self.directory = directory
        self.suiteName = suiteName
        self.fileManager = fileManager
    }

    static func applicationSupportDirectory(fileManager: FileManager = .default) throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("CR Way", isDirectory: true)
    }

    func load() -> (rail: Rail, warning: RailWarning?) {
        if let rail = decode(defaults().data(forKey: RailKey.snapshot)) {
            return (rail, nil)
        }
        if let rail = decode(read(fileURL)) {
            return (rail, nil)
        }
        if let rail = decode(defaults().data(forKey: RailKey.backup)) {
            return (rail, .recoveredFromBackup)
        }
        if let rail = decode(read(backupURL)) {
            return (rail, .recoveredFromBackup)
        }
        let hadPayload = defaults().data(forKey: RailKey.snapshot) != nil
            || fileManager.fileExists(atPath: fileURL.path)
        return (.empty, hadPayload ? .startedEmpty : nil)
    }

    func save(_ rail: Rail) throws {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try RailDocument.encode(rail)
        let box = defaults()
        if let current = box.data(forKey: RailKey.snapshot) {
            box.set(current, forKey: RailKey.backup)
        }
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: backupURL)
            try? fileManager.copyItem(at: fileURL, to: backupURL)
        }
        box.set(data, forKey: RailKey.snapshot)
        try data.write(to: fileURL, options: .atomic)
    }

    func wipe() throws {
        let box = defaults()
        box.removeObject(forKey: RailKey.snapshot)
        box.removeObject(forKey: RailKey.backup)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
        if fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.removeItem(at: backupURL)
        }
    }

    func demoPlanted() -> Bool {
        defaults().object(forKey: RailKey.demo) != nil
    }

    func markDemoPlanted() {
        defaults().set(true, forKey: RailKey.demo)
    }

    private func decode(_ data: Data?) -> Rail? {
        guard let data else { return nil }
        return try? RailDocument.decode(data)
    }

    private func read(_ url: URL) -> Data? {
        try? Data(contentsOf: url)
    }

    private var fileURL: URL {
        directory.appendingPathComponent("rail.json", isDirectory: false)
    }

    private var backupURL: URL {
        directory.appendingPathComponent("rail.json.backup", isDirectory: false)
    }

    private func defaults() -> UserDefaults {
        if let suiteName {
            return UserDefaults(suiteName: suiteName) ?? .standard
        }
        return .standard
    }
}
