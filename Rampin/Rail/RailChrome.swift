import Foundation
import Observation
import SwiftUI

/// Role: Rail. Presentation fold over RailStore. Views call spreadRail, liftWork, hookRampin, dropRampin, and retractNewestMark and never keep a second rail enum.
@MainActor
@Observable
final class RailChrome {
    let store: RailStore
    private(set) var rail: Rail
    var isBooting: Bool
    var showsOnboarding: Bool
    var cover: RailCover?
    var recoveredNotice: Bool
    var isSpreading: Bool
    var spreadBusy: Bool
    var isRetracting: Bool
    var retractBusy: Bool
    var liftBusy: UUID?
    var hookBusy: UUID?
    var isSeeking: Bool
    var query: String
    var seekHits: [CatalogRow]
    var seekFault: String?
    var railFault: String?
    var crateNote: String?
    var stockingObjectID: String?
    var hookPulse: Int
    var showSuccess: Bool
    var dayStamp: Int
    private var cueConsumed: Bool
    private var seekTask: Task<Void, Never>?
    private var successTask: Task<Void, Never>?

    init(store: RailStore, isBooting: Bool = true) {
        self.store = store
        self.rail = store.rail
        self.isBooting = isBooting
        self.showsOnboarding = false
        self.cover = nil
        self.recoveredNotice = false
        self.isSpreading = false
        self.spreadBusy = false
        self.isRetracting = false
        self.retractBusy = false
        self.liftBusy = nil
        self.hookBusy = nil
        self.isSeeking = false
        self.query = ""
        self.seekHits = []
        self.seekFault = nil
        self.railFault = nil
        self.crateNote = nil
        self.stockingObjectID = nil
        self.hookPulse = 0
        self.showSuccess = false
        self.dayStamp = Daykey.stamp(Date(), calendar: .current)
        self.cueConsumed = false
    }

    static func live() -> RailChrome {
        RailChrome(store: RailStore())
    }

    func boot() async {
        guard isBooting else { return }
        await store.load()
        sync()
        recoveredNotice = store.warning != nil
        showsOnboarding = !rail.onboardingComplete
        isBooting = false
        if query.isEmpty {
            seekHits = rail.fallbackRows(shelf: PmaShelf.bundled.rows)
        }
        if !showsOnboarding {
            consumeCue()
        }
        await CanvasFace.shared.loadMany(rail.works.map(\.imageURL) + seekHits.map(\.imageURL))
    }

    func flush() async {
        await store.flush()
        sync()
    }

    func refreshDay() {
        dayStamp = Daykey.stamp(Date(), calendar: .current)
    }

    func handle(phase: ScenePhase) async {
        switch phase {
        case .inactive, .background:
            await flush()
        case .active:
            refreshDay()
        @unknown default:
            break
        }
    }

    func finishOnboarding() async {
        await store.setOnboardingComplete(true)
        await store.flush()
        sync()
        showsOnboarding = false
        consumeCue()
    }

    func replayOnboarding() {
        cover = nil
        showsOnboarding = true
        Task {
            await store.setOnboardingComplete(false)
            await store.flush()
            sync()
        }
    }

    func present(_ cover: RailCover) {
        self.cover = cover
    }

    func handle(_ job: RailJob) {
        switch job {
        case .quiz:
            cover = nil
        case .spread:
            cover = nil
            Task { await spreadRail() }
        case .lift:
            cover = nil
            Task { await liftFromIntent() }
        case .hook:
            cover = nil
            Task { await hookFromIntent() }
        case .explore, .saved, .settings, .twist:
            cover = job.cover
        }
    }

    func handle(url: URL) {
        guard let job = RailJob.parse(url) else { return }
        handle(job)
    }

    func spreadRail() async {
        guard !isSpreading else { return }
        isSpreading = true
        let pulse = Task {
            try await Task.sleep(for: .milliseconds(150))
            if !Task.isCancelled { spreadBusy = true }
        }
        do {
            try await store.spreadRail()
            showSuccess = false
            sync()
            if store.lastWriteError == nil {
                railFault = nil
            }
        } catch {
            railFault = RailCopy.fault(error)
            sync()
        }
        pulse.cancel()
        spreadBusy = false
        isSpreading = false
        sync()
    }

    func liftWork(_ workID: UUID) async {
        guard liftBusy == nil else { return }
        liftBusy = workID
        do {
            try await store.liftWork(workID)
            sync()
            if store.lastWriteError == nil {
                railFault = nil
            }
        } catch {
            railFault = RailCopy.fault(error)
            sync()
        }
        liftBusy = nil
        sync()
    }

    func hookRampin(_ rampinID: UUID) async {
        guard hookBusy == nil else { return }
        if rail.liftedWork == nil, let waiting = rail.waitingOnRail.first {
            await liftWork(waiting.id)
        }
        guard hookBusy == nil else { return }
        hookBusy = rampinID
        let hooksBefore = rail.hookMarks.count
        do {
            try await store.hookRampin(rampinID)
            sync()
            if rail.hookMarks.count > hooksBefore {
                hookPulse += 1
                flashSuccess()
            }
            if store.lastWriteError == nil {
                railFault = nil
            }
        } catch {
            railFault = RailCopy.fault(error)
            sync()
        }
        hookBusy = nil
        sync()
    }

    func dropRampin(_ rampinID: UUID) async {
        guard hookBusy == nil else { return }
        hookBusy = rampinID
        do {
            try await store.dropRampin(rampinID)
            sync()
            if store.lastWriteError == nil {
                railFault = nil
            }
        } catch {
            railFault = RailCopy.fault(error)
            sync()
        }
        hookBusy = nil
        sync()
    }

    func retractNewestMark() async {
        guard !isRetracting else { return }
        isRetracting = true
        let pulse = Task {
            try await Task.sleep(for: .milliseconds(150))
            if !Task.isCancelled { retractBusy = true }
        }
        do {
            try await store.retractNewestMark()
            showSuccess = false
            sync()
            if store.lastWriteError == nil {
                railFault = nil
            }
        } catch {
            railFault = RailCopy.fault(error)
            sync()
        }
        pulse.cancel()
        retractBusy = false
        isRetracting = false
        sync()
    }

    func fileWork(_ row: CatalogRow) async {
        guard stockingObjectID == nil else { return }
        stockingObjectID = row.objectID
        do {
            let focus = try await store.fileWork(row)
            sync()
            switch focus {
            case .inserted:
                crateNote = RailCopy.filedNote
            case .focused:
                crateNote = RailCopy.focusedNote
            }
            railFault = nil
        } catch {
            crateNote = RailCopy.fault(error)
        }
        stockingObjectID = nil
        if store.lastWriteError != nil {
            railFault = RailCopy.writeFailed
        }
        sync()
    }

    func scheduleSeek() {
        seekTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        seekTask = Task { await seek(trimmed) }
    }

    func resetAllData() async {
        seekTask?.cancel()
        successTask?.cancel()
        await store.resetAllData()
        sync()
        cover = nil
        query = ""
        seekHits = rail.fallbackRows(shelf: PmaShelf.bundled.rows)
        seekFault = nil
        railFault = nil
        crateNote = nil
        recoveredNotice = false
        showSuccess = false
        showsOnboarding = true
        cueConsumed = true
    }

    func work(for id: UUID?) -> Work? {
        guard let id else { return nil }
        return rail.works.first { $0.id == id }
    }

    func work(for mark: HookMark) -> Work? {
        work(for: mark.workID)
    }

    func work(for mark: DropMark) -> Work? {
        work(for: mark.workID)
    }

    func work(for peg: Rampin) -> Work? {
        work(for: peg.workID)
    }

    var heroWork: Work? {
        if let lifted = rail.liftedWork { return lifted }
        if let waiting = rail.waitingOnRail.first { return waiting }
        return rail.planted.compactMap { work(for: $0) }.first
    }

    var companionWorks: [Work] {
        let heroID = heroWork?.id
        return rail.planted.compactMap { work(for: $0) }.filter { $0.id != heroID }
    }

    var recentHooks: [HookMark] {
        Array(rail.hookMarks.suffix(4).reversed())
    }

    var primaryHookEnabled: Bool {
        rail.fold == .spread && hookBusy == nil && (rail.liftedWork != nil || rail.waitingOnRail.first != nil)
    }

    func hookPrimary() async {
        if rail.liftedWork == nil, let waiting = rail.waitingOnRail.first {
            await liftWork(waiting.id)
        }
        await hookFromIntent()
    }

    var spreadEnabled: Bool {
        rail.canSpread && !isSpreading
    }

    var retractEnabled: Bool {
        !rail.peelLog.isEmpty && !isRetracting
    }

    var quizIsEmpty: Bool {
        rail.fold == .bare
    }

    var savedIsEmpty: Bool {
        rail.settledWorks.isEmpty && rail.reviewableHooks.isEmpty && rail.reviewableDrops.isEmpty
    }

    var exploreIsEmpty: Bool {
        seekHits.isEmpty && !isSeeking
    }

    var settingsIsEmpty: Bool {
        rail.works.isEmpty && rail.hookMarks.isEmpty && rail.dropMarks.isEmpty
    }

    private func liftFromIntent() async {
        guard let waiting = rail.waitingOnRail.first else {
            railFault = RailCopy.fault(RailFault.notWaiting)
            return
        }
        await liftWork(waiting.id)
    }

    private func hookFromIntent() async {
        guard let lifted = rail.liftedWork else {
            railFault = RailCopy.fault(RailFault.hookWithoutLift)
            return
        }
        if let match = rail.planted.first(where: { $0.names(lifted) }) {
            await hookRampin(match.id)
            return
        }
        guard let first = rail.planted.first else {
            railFault = RailCopy.fault(RailFault.unknownRampin)
            return
        }
        await hookRampin(first.id)
    }

    private func seek(_ trimmed: String) async {
        if trimmed.isEmpty {
            isSeeking = false
            seekFault = nil
            seekHits = rail.fallbackRows(shelf: PmaShelf.bundled.rows)
            return
        }
        let pulse = Task {
            try await Task.sleep(for: .milliseconds(150))
            if !Task.isCancelled { isSeeking = true }
        }
        defer {
            pulse.cancel()
            isSeeking = false
        }
        do {
            let hits = try await store.seek(trimmed)
            if Task.isCancelled { return }
            sync()
            seekHits = hits
            if hits.isEmpty {
                seekFault = RailCopy.seek(.missing)
            } else if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
                      hits.allSatisfy({ row in
                          PmaShelf.bundled.rows.contains(where: { $0.objectID == row.objectID })
                      }) {
                seekFault = RailCopy.shelfNote
            } else {
                seekFault = nil
            }
        } catch is CancellationError {
            return
        } catch let fault as CatalogFault where fault == .cancelled {
            return
        } catch let fault as CatalogFault {
            if Task.isCancelled { return }
            sync()
            seekHits = rail.fallbackRows(shelf: PmaShelf.bundled.rows)
            seekFault = RailCopy.seek(fault)
        } catch {
            if Task.isCancelled { return }
            sync()
            seekHits = rail.fallbackRows(shelf: PmaShelf.bundled.rows)
            seekFault = RailCopy.seek(.transport)
        }
    }

    private func flashSuccess() {
        successTask?.cancel()
        showSuccess = true
        successTask = Task {
            try? await Task.sleep(for: .milliseconds(900))
            if !Task.isCancelled {
                showSuccess = false
            }
        }
    }

    private func consumeCue() {
        if let hook = RailLinks.consume(
            onboardingComplete: rail.onboardingComplete,
            consumed: &cueConsumed
        ) {
            switch hook.sheet {
            case .quiz:
                cover = nil
            case .explore:
                cover = .explore
            case .saved:
                cover = .saved
            case .settings:
                cover = .settings
            }
        }
    }

    private func sync() {
        rail = store.rail
        if store.lastWriteError != nil {
            railFault = RailCopy.writeFailed
        }
    }
}
