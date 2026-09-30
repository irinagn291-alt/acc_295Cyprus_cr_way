import Foundation
import Observation

/// Role: Rail. Observable fold owner. Memory is the source of truth. UserDefaults is the projection. Views call spreadRail, liftWork, hookRampin, dropRampin, and retractNewestMark.
@MainActor
@Observable
final class RailStore {
    static let seekDebounceNanoseconds: UInt64 = 500_000_000

    private(set) var rail: Rail
    private(set) var warning: RailWarning?
    private(set) var lastWriteError: String?

    private let vault: RailVault
    private let client: CatalogClient
    private let shelf: PmaShelf
    private let writeDelayNanoseconds: UInt64
    private let seekDelayNanoseconds: UInt64
    private let plantDemo: Bool
    private var persistTask: Task<Void, Never>?
    private var seekTask: Task<[CatalogRow], Error>?

    init(
        directory: URL,
        suiteName: String? = nil,
        client: CatalogClient = CatalogClient(),
        shelf: PmaShelf = .bundled,
        writeDelayNanoseconds: UInt64 = 280_000_000,
        seekDelayNanoseconds: UInt64 = RailStore.seekDebounceNanoseconds,
        plantDemo: Bool = false
    ) {
        self.vault = RailVault(directory: directory, suiteName: suiteName)
        self.client = client
        self.shelf = shelf
        self.writeDelayNanoseconds = writeDelayNanoseconds
        self.seekDelayNanoseconds = seekDelayNanoseconds
        self.plantDemo = plantDemo
        self.rail = .empty
        self.warning = nil
        self.lastWriteError = nil
    }

    convenience init() {
        let directory: URL
        do {
            directory = try RailVault.applicationSupportDirectory()
        } catch {
            directory = FileManager.default.temporaryDirectory.appendingPathComponent("CR Way", isDirectory: true)
        }
        self.init(directory: directory, plantDemo: true)
    }

    func load() async {
        let loaded = await vault.load()
        var next = loaded.rail
        next.applyShelfImages(shelf.rows)
        #if targetEnvironment(simulator)
        if plantDemo {
            let already = await vault.demoPlanted()
            if !already, next.works.isEmpty {
                next = RailSeed.rail(shelf: shelf.rows)
                await vault.markDemoPlanted()
            }
        }
        #endif
        rail = next
        warning = loaded.warning
        lastWriteError = nil
        if next != loaded.rail {
            await persistNow()
        }
    }

    func spreadRail() async throws {
        var next = rail
        try next.spreadRail()
        rail = next
        await persistNow()
    }

    func liftWork(_ workID: UUID) async throws {
        var next = rail
        try next.liftWork(workID)
        rail = next
        await persistNow()
    }

    func hookRampin(_ rampinID: UUID, now: Date = Date(), calendar: Calendar = .current) async throws {
        var next = rail
        _ = try next.hookRampin(rampinID, now: now, calendar: calendar)
        rail = next
        await persistNow()
    }

    func dropRampin(_ rampinID: UUID, now: Date = Date(), calendar: Calendar = .current) async throws {
        var next = rail
        try next.dropRampin(rampinID, now: now, calendar: calendar)
        rail = next
        await persistNow()
    }

    func retractNewestMark() async throws {
        var next = rail
        try next.retractNewestMark()
        rail = next
        await persistNow()
    }

    @discardableResult
    func fileWork(_ row: CatalogRow, now: Date = Date(), calendar: Calendar = .current) async throws -> WriteFocus {
        var next = rail
        let focus = try next.fileWork(row, now: now, calendar: calendar)
        rail = next
        await persistNow()
        return focus
    }

    func seek(_ query: String) async throws -> [CatalogRow] {
        seekTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return rail.fallbackRows(shelf: shelf.rows)
        }
        let client = self.client
        let delay = seekDelayNanoseconds
        let task = Task { () throws -> [CatalogRow] in
            if delay > 0 {
                try await Task.sleep(nanoseconds: delay)
            }
            try Task.checkCancellation()
            return try await client.search(query: trimmed)
        }
        seekTask = task
        do {
            let rows = try await task.value
            if Task.isCancelled { throw CatalogFault.cancelled }
            if rows.isEmpty {
                return rail.fallbackRows(shelf: shelf.rows)
            }
            var next = rail
            next.remember(rows)
            rail = next
            await persistNow()
            return rows
        } catch is CancellationError {
            throw CatalogFault.cancelled
        } catch let fault as CatalogFault where fault == .cancelled {
            throw fault
        } catch {
            return rail.fallbackRows(shelf: shelf.rows)
        }
    }

    func setOnboardingComplete(_ flag: Bool) async {
        var next = rail
        next.setOnboardingComplete(flag)
        rail = next
        schedulePersist()
    }

    func flush() async {
        persistTask?.cancel()
        persistTask = nil
        await persistNow()
    }

    func resetAllData() async {
        persistTask?.cancel()
        persistTask = nil
        rail = .empty
        warning = nil
        lastWriteError = nil
        do {
            try await vault.wipe()
        } catch {
            lastWriteError = error.localizedDescription
        }
    }

    private func schedulePersist() {
        persistTask?.cancel()
        let delay = writeDelayNanoseconds
        persistTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.persistNow()
        }
    }

    private func persistNow() async {
        persistTask?.cancel()
        persistTask = nil
        do {
            try await vault.save(rail)
            lastWriteError = nil
        } catch {
            lastWriteError = error.localizedDescription
        }
    }
}
