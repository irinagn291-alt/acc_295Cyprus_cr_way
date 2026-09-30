import SwiftUI

/// Role: Work. Explore sheet. Philadelphia Museum of Art search plus the local PMA shelf. Empty, populated, and error.
struct ExploreView: View {
    @Bindable var chrome: RailChrome
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        NavigationStack {
            Group {
                if chrome.exploreIsEmpty {
                    BarePage(
                        art: RailArt.emptyList,
                        headline: RailCopy.exploreHeadline,
                        line: RailCopy.exploreLine,
                        actionTitle: "Search"
                    ) {
                        chrome.query = "eakins"
                        chrome.scheduleSeek()
                    }
                } else {
                    populated
                }
            }
            .background(RailInk.background.ignoresSafeArea())
            .navigationTitle(RailCopy.explore)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(RailIconStyle())
                    .accessibilityLabel("Close Explore")
                }
            }
        }
        .task {
            if chrome.seekHits.isEmpty {
                chrome.scheduleSeek()
            }
            await CanvasFace.shared.loadMany(chrome.seekHits.flatMap { CanvasFace.imageURLs(for: $0) })
        }
        .onChange(of: chrome.query) { _, _ in
            chrome.scheduleSeek()
        }
    }

    private var populated: some View {
        List {
            Section {
                TextField("Maker or title", text: $chrome.query)
                    .font(RailType.font(.body, size: typeSize))
                    .foregroundStyle(RailInk.ink)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .accessibilityLabel("Search the museum")
            }
            if let fault = chrome.seekFault, !fault.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: RailSpace.inner) {
                        Text(fault)
                            .font(RailType.font(.body, size: typeSize))
                            .foregroundStyle(RailInk.ink)
                        Button("Try again") {
                            chrome.scheduleSeek()
                        }
                        .buttonStyle(RetractRailStyle())
                    }
                    .listRowBackground(RailInk.surface)
                }
            }
            if chrome.isSeeking {
                Section {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: RailSpace.hit)
                        .listRowBackground(RailInk.surface)
                }
            }
            if let note = chrome.crateNote {
                Section {
                    Text(note)
                        .font(RailType.font(.caption, size: typeSize))
                        .foregroundStyle(RailInk.muted)
                        .listRowBackground(RailInk.surface)
                }
            }
            Section {
                ForEach(chrome.seekHits) { row in
                    rowCard(row)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(RailInk.background)
    }

    private func rowCard(_ row: CatalogRow) -> some View {
        let focused = chrome.rail.focusedWorkID.flatMap { id in
            chrome.rail.works.first { $0.id == id && $0.objectID == row.objectID }
        } != nil
        let already = chrome.rail.works.contains { $0.objectID == row.objectID }
        return HStack(alignment: .center, spacing: RailSpace.card) {
            Color.clear
                .frame(width: RailSpace.step(8), height: RailSpace.step(8))
                .overlay {
                    ZStack {
                        RailInk.surface
                        if let face = CanvasFace.shared.picture(for: row) {
                            face
                                .resizable()
                                .scaledToFill()
                        } else {
                            CanvasThumb(title: row.title)
                        }
                    }
                    .clipped()
                }
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: RailRadius.chip, style: .continuous))
                .task {
                    await CanvasFace.shared.loadMany(CanvasFace.imageURLs(for: row))
                }
            VStack(alignment: .leading, spacing: RailSpace.gap) {
                Text(row.title)
                    .font(RailType.font(.headline, size: typeSize))
                    .foregroundStyle(RailInk.ink)
                    .lineLimit(2)
                Text(row.artist)
                    .font(RailType.font(.caption, size: typeSize))
                    .foregroundStyle(RailInk.muted)
                    .lineLimit(1)
                if already {
                    Text(focused ? RailCopy.focusedNote : "On the rail")
                        .font(RailType.font(.micro, size: typeSize))
                        .foregroundStyle(RailInk.ink)
                }
            }
            Spacer(minLength: 0)
            Button(already ? "Keep" : "Save") {
                Task { await chrome.fileWork(row) }
            }
            .buttonStyle(SpreadPillStyle(isLoading: chrome.stockingObjectID == row.objectID))
            .frame(maxWidth: RailSpace.step(12))
            .disabled(chrome.stockingObjectID != nil)
            .accessibilityLabel(already ? "Keep this work on the rail" : "Save this work")
        }
        .padding(.vertical, RailSpace.inner)
        .listRowBackground(focused ? RailInk.muted.opacity(0.12) : RailInk.surface)
        .listRowInsets(EdgeInsets(
            top: RailSpace.inner,
            leading: RailSpace.outer,
            bottom: RailSpace.inner,
            trailing: RailSpace.outer
        ))
        .accessibilityElement(children: .contain)
    }
}
