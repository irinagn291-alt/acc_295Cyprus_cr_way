import SwiftUI

/// Role: Work. Study sheet for one painting. The note stays local. A wall label is written only after the work is saved.
struct StudySheet: View {
    @Bindable var chrome: RailChrome
    var row: CatalogRow
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var draft = ""
    @State private var notice: String?
    @State private var saving = false
    @State private var faces = CanvasFace.shared

    private var work: Work? {
        chrome.rail.works.first { $0.objectID == row.objectID }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: RailSpace.card) {
                    picture
                    Text(row.title)
                        .font(RailType.font(.title, size: typeSize))
                        .foregroundStyle(RailInk.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(row.artist)
                        .font(RailType.font(.headline, size: typeSize))
                        .foregroundStyle(RailInk.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    if let dated = row.dated, !dated.isEmpty {
                        Text(dated)
                            .font(RailType.font(.caption, size: typeSize))
                            .foregroundStyle(RailInk.muted)
                            .monospacedDigit()
                    }
                    if let text = PmaShelf.studyText(for: row.objectID) ?? row.studyNote {
                        Text(text)
                            .font(RailType.font(.body, size: typeSize))
                            .foregroundStyle(RailInk.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    labelBlock
                }
                .padding(RailSpace.outer)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(RailInk.background.ignoresSafeArea())
            .navigationTitle(RailCopy.study)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(RailIconStyle())
                    .accessibilityLabel("Close Study")
                }
            }
        }
        .onAppear {
            draft = chrome.rail.labelText(for: row.objectID) ?? ""
        }
        .task {
            await faces.loadMany(CanvasFace.imageURLs(for: row))
        }
    }

    private var picture: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: RailSpace.step(28))
            .overlay {
                ZStack {
                    RailInk.surface
                    if let face = faces.picture(for: row) {
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
            .clipShape(RoundedRectangle(cornerRadius: RailRadius.card, style: .continuous))
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var labelBlock: some View {
        if work != nil {
            VStack(alignment: .leading, spacing: RailSpace.inner) {
                Text(RailCopy.wallLabel)
                    .font(RailType.font(.headline, size: typeSize))
                    .foregroundStyle(RailInk.ink)
                TextField(RailCopy.wallPlaceholder, text: $draft, axis: .vertical)
                    .font(RailType.font(.body, size: typeSize))
                    .foregroundStyle(RailInk.ink)
                    .lineLimit(3 ... 6)
                    .padding(RailSpace.card)
                    .background(RailInk.surface, in: RoundedRectangle(cornerRadius: RailRadius.card, style: .continuous))
                    .accessibilityLabel(RailCopy.wallLabel)
                    .onChange(of: draft) { _, newValue in
                        if newValue.count > Rail.labelLimit {
                            draft = String(newValue.prefix(Rail.labelLimit))
                        }
                    }
                Text(RailCopy.labelCount(draft.count))
                    .font(RailType.font(.micro, size: typeSize))
                    .foregroundStyle(RailInk.muted)
                    .monospacedDigit()
                Button(RailCopy.keepLabel) {
                    Task { await keepLabel() }
                }
                .buttonStyle(SpreadPillStyle(isLoading: saving))
                .disabled(saving)
                if let notice {
                    Text(notice)
                        .font(RailType.font(.caption, size: typeSize))
                        .foregroundStyle(RailInk.ink)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: RailSpace.inner) {
                Text(RailCopy.labelNeedsSave)
                    .font(RailType.font(.body, size: typeSize))
                    .foregroundStyle(RailInk.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Save") {
                    Task { await saveWork() }
                }
                .buttonStyle(SpreadPillStyle(isLoading: chrome.stockingObjectID == row.objectID))
                .disabled(chrome.stockingObjectID != nil)
                .accessibilityLabel("Save this work")
            }
        }
    }

    private func keepLabel() async {
        guard !saving else { return }
        saving = true
        let clearing = draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        do {
            try await chrome.writeLabel(objectID: row.objectID, text: draft)
            notice = clearing ? RailCopy.labelCleared : RailCopy.labelKept
        } catch {
            notice = RailCopy.fault(error)
        }
        saving = false
    }

    private func saveWork() async {
        await chrome.fileWork(row)
    }
}
