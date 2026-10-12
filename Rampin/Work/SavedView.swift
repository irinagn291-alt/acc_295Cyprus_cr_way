import SwiftUI

/// Role: Work. Saved sheet. Settled works plus HookMarks and DropMarks. Empty, populated, and error.
struct SavedView: View {
    @Bindable var chrome: RailChrome
    @State private var faces = CanvasFace.shared
    @State private var study: CatalogRow?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        NavigationStack {
            Group {
                if chrome.savedIsEmpty {
                    BarePage(
                        art: RailArt.emptyList,
                        headline: chrome.store.lastWriteError != nil ? RailCopy.writeFailed : RailCopy.savedHeadline,
                        line: chrome.store.lastWriteError != nil
                            ? "Try retract after the rail writes again."
                            : RailCopy.savedLine,
                        actionTitle: chrome.store.lastWriteError != nil ? "Try again" : RailCopy.explore
                    ) {
                        if chrome.store.lastWriteError != nil {
                            Task { await chrome.flush() }
                        } else {
                            chrome.present(.explore)
                        }
                    }
                } else {
                    populated
                }
            }
            .background(RailInk.background.ignoresSafeArea())
            .navigationTitle(RailCopy.saved)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(RailIconStyle())
                    .accessibilityLabel("Close Saved")
                }
            }
        }
        .task {
            await faces.loadMany(chrome.rail.works.flatMap { CanvasFace.imageURLs(for: $0) })
        }
        .sheet(item: $study) { row in
            StudySheet(chrome: chrome, row: row)
                .presentationDetents([.large])
                .presentationCornerRadius(RailRadius.card)
                .presentationBackground(RailInk.surface)
                .presentationDragIndicator(.visible)
        }
    }

    private var populated: some View {
        List {
            if let fault = chrome.railFault, !fault.isEmpty {
                Section {
                    Text(fault)
                        .font(RailType.font(.body, size: typeSize))
                        .foregroundStyle(RailInk.ink)
                        .listRowBackground(RailInk.surface)
                }
            }
            Section {
                Text(RailCopy.deviceLine(
                    seated: chrome.rail.settledWorks.count,
                    labels: chrome.rail.labels.count,
                    runs: chrome.rail.runs.count
                ))
                .font(RailType.font(.body, size: typeSize))
                .foregroundStyle(RailInk.ink)
                .listRowBackground(RailInk.surface)
                if chrome.rail.canSpreadMisses {
                    VStack(alignment: .leading, spacing: RailSpace.inner) {
                        Text(RailCopy.missesLine)
                            .font(RailType.font(.caption, size: typeSize))
                            .foregroundStyle(RailInk.muted)
                            .fixedSize(horizontal: false, vertical: true)
                        Button(RailCopy.spreadMisses) {
                            dismiss()
                            Task { await chrome.spreadRail(misses: true) }
                        }
                        .buttonStyle(SpreadPillStyle(isLoading: chrome.spreadBusy))
                        .disabled(!chrome.spreadEnabled)
                    }
                    .padding(.vertical, RailSpace.inner)
                    .listRowBackground(RailInk.surface)
                }
            }
            if !chrome.rail.runs.isEmpty {
                Section(RailCopy.runs) {
                    ForEach(chrome.rail.runs.reversed()) { run in
                        runRow(run)
                    }
                }
            }
            if !chrome.rail.makerTallies.isEmpty {
                Section(RailCopy.makersSeated) {
                    ForEach(chrome.rail.makerTallies, id: \.name) { tally in
                        Text(RailCopy.makerTally(name: tally.name, count: tally.count))
                            .font(RailType.font(.body, size: typeSize))
                            .foregroundStyle(RailInk.ink)
                            .listRowBackground(RailInk.surface)
                    }
                }
            }
            if !chrome.rail.settledWorks.isEmpty {
                Section("Seated") {
                    ForEach(chrome.rail.settledWorks) { work in
                        Button {
                            study = studyRow(for: work)
                        } label: {
                            workRow(work)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Study \(work.title)")
                    }
                }
            }
            if !chrome.rail.reviewableHooks.isEmpty {
                Section("Hooks") {
                    ForEach(chrome.rail.reviewableHooks.reversed()) { mark in
                        markRow(
                            title: mark.cartelText,
                            work: chrome.work(for: mark),
                            daykey: mark.daykey,
                            kind: "Hook"
                        )
                    }
                }
            }
            if !chrome.rail.reviewableDrops.isEmpty {
                Section("Drops") {
                    ForEach(chrome.rail.reviewableDrops.reversed()) { mark in
                        markRow(
                            title: mark.cartelText,
                            work: chrome.work(for: mark),
                            daykey: mark.daykey,
                            kind: "Drop"
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(RailInk.background)
    }

    private func workRow(_ work: Work) -> some View {
        HStack(alignment: .center, spacing: RailSpace.card) {
            thumb(for: work)
            VStack(alignment: .leading, spacing: RailSpace.gap) {
                Text(work.title)
                    .font(RailType.font(.headline, size: typeSize))
                    .foregroundStyle(RailInk.ink)
                    .lineLimit(2)
                Text(work.artist)
                    .font(RailType.font(.caption, size: typeSize))
                    .foregroundStyle(RailInk.muted)
                    .lineLimit(1)
                if let dated = work.dated, !dated.isEmpty {
                    Text(dated)
                        .font(RailType.font(.micro, size: typeSize))
                        .foregroundStyle(RailInk.muted)
                        .monospacedDigit()
                }
                if let note = PmaShelf.note(for: work.objectID) {
                    Text(note)
                        .font(RailType.font(.caption, size: typeSize))
                        .foregroundStyle(RailInk.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(3)
                }
                if let label = chrome.rail.labelText(for: work.objectID) {
                    Text(label)
                        .font(RailType.font(.caption, size: typeSize))
                        .foregroundStyle(RailInk.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(3)
                }
                Text(RailFigures.dayLabel(work.daykey))
                    .font(RailType.font(.micro, size: typeSize))
                    .foregroundStyle(RailInk.muted)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, RailSpace.inner)
        .listRowBackground(RailInk.surface)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(work.title), \(work.artist)")
    }

    private func markRow(title: String, work: Work?, daykey: Int, kind: String) -> some View {
        HStack(alignment: .center, spacing: RailSpace.card) {
            if let work {
                thumb(for: work)
            } else {
                Color.clear
                    .frame(width: RailSpace.step(8), height: RailSpace.step(8))
                    .overlay {
                        CanvasThumb(title: title)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: RailRadius.chip, style: .continuous))
            }
            VStack(alignment: .leading, spacing: RailSpace.gap) {
                Text(title)
                    .font(RailType.font(.headline, size: typeSize))
                    .foregroundStyle(RailInk.ink)
                    .lineLimit(2)
                Text(markSubtitle(work: work, kind: kind, title: title))
                    .font(RailType.font(.caption, size: typeSize))
                    .foregroundStyle(RailInk.muted)
                    .lineLimit(1)
                HStack(spacing: RailSpace.inner) {
                    Text(kind)
                        .font(RailType.font(.micro, size: typeSize))
                        .foregroundStyle(RailInk.ink)
                        .padding(.horizontal, RailSpace.inner)
                        .padding(.vertical, RailSpace.gap)
                        .background(RailInk.background, in: Capsule())
                    Text(RailFigures.dayLabel(daykey))
                        .font(RailType.font(.micro, size: typeSize))
                        .foregroundStyle(RailInk.muted)
                        .monospacedDigit()
                }
            }
        }
        .padding(.vertical, RailSpace.inner)
        .listRowBackground(RailInk.surface)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(kind), \(title)")
    }

    private func studyRow(for work: Work) -> CatalogRow {
        CatalogRow(
            objectID: work.objectID,
            artist: work.artist,
            title: work.title,
            imageURLString: work.imageURLString,
            dated: work.dated,
            note: PmaShelf.note(for: work.objectID)
        )
    }

    private func runRow(_ run: RailRun) -> some View {
        let titles = run.objectIDs.compactMap { objectID in
            chrome.rail.works.first { $0.objectID == objectID }?.title
        }
        return VStack(alignment: .leading, spacing: RailSpace.gap) {
            Text(titles.joined(separator: ", "))
                .font(RailType.font(.headline, size: typeSize))
                .foregroundStyle(RailInk.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(RailCopy.runLine(field: run.field, drops: run.drops))
                .font(RailType.font(.caption, size: typeSize))
                .foregroundStyle(RailInk.muted)
            Text(RailFigures.dayLabel(run.daykey))
                .font(RailType.font(.micro, size: typeSize))
                .foregroundStyle(RailInk.muted)
                .monospacedDigit()
        }
        .padding(.vertical, RailSpace.inner)
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowBackground(RailInk.surface)
        .accessibilityElement(children: .combine)
    }

    private func markSubtitle(work: Work?, kind: String, title: String) -> String {
        if let artist = work?.artist, !artist.isEmpty, artist != title {
            return artist
        }
        return kind == "Hook" ? RailCopy.caption(.hooked) : "Returned to the rail"
    }

    private func thumb(for work: Work) -> some View {
        Color.clear
            .frame(width: RailSpace.step(8), height: RailSpace.step(8))
            .overlay {
                ZStack {
                    RailInk.surface
                    if let face = faces.picture(for: work) {
                        face
                            .resizable()
                            .scaledToFill()
                    } else {
                        CanvasThumb(title: work.title)
                    }
                }
                .clipped()
            }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: RailRadius.chip, style: .continuous))
            .task(id: work.objectID) {
                await faces.loadWork(work)
            }
    }
}
