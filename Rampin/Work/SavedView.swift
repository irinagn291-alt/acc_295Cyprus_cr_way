import SwiftUI

/// Role: Work. Saved sheet. Settled works plus HookMarks and DropMarks. Empty, populated, and error.
struct SavedView: View {
    @Bindable var chrome: RailChrome
    @State private var faces = CanvasFace.shared
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
            if !chrome.rail.settledWorks.isEmpty {
                Section("Seated") {
                    ForEach(chrome.rail.settledWorks) { work in
                        workRow(work)
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
