import SwiftUI
import Foundation

struct ImageViewerContext: Identifiable, Equatable {
    let note: Note
    let images: [NoteImage]
    let initialIndex: Int
    var id: String { note.id.uuidString + "_\(initialIndex)" }
}

struct GalleryOverviewView: View {
    let notes: [Note]
    let noteManager: NoteManager
    let folders: [Folder]
    let showFolderName: Bool

    @State private var selectedImageContext: ImageViewerContext? = nil
    @State private var collapsedNotes: Set<UUID> = []

    func folderName(for note: Note) -> String {
        guard let folderId = note.folderId else { return String(localized: "All Notes") }
        return folders.first(where: { $0.id == folderId })?.name ?? String(localized: "Unknown")
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(notes.filter { !$0.images.isEmpty }) { note in
                    VStack(alignment: .leading, spacing: 6) {
                        // Title row with chevron and tap to collapse
                        Button(action: {
                            if collapsedNotes.contains(note.id) {
                                collapsedNotes.remove(note.id)
                            } else {
                                collapsedNotes.insert(note.id)
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: collapsedNotes.contains(note.id) ? "chevron.right" : "chevron.down")
                                    .foregroundColor(.secondary)
                                Image(systemName: "note.text")
                                    .foregroundColor(.accentColor)
                                Text(note.title.isEmpty ? String(localized: "Untitled Note") : note.title)
                                    .font(.headline)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)

                        // Folder name
                        if showFolderName {
                            HStack(spacing: 6) {
                                Image(systemName: "folder")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(folderName(for: note))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.bottom, 2)
                        }

                        // Images grid (collapsible)
                        if !collapsedNotes.contains(note.id) {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 8)], spacing: 8) {
                                if note.isLocked {
                                    ForEach(note.images.indices, id: \.self) { _ in
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.gray.opacity(0.25))
                                                .frame(width: 84, height: 84)
                                            Image(systemName: "lock.fill")
                                                .foregroundColor(.gray)
                                                .font(.title2)
                                        }
                                    }
                                } else {
                                    ForEach(note.images.indices, id: \.self) { idx in
                                        let img = note.images[idx]
                                        ZStack(alignment: .bottomTrailing) {
                                            if let uiImage = noteManager.loadImage(for: note, image: img) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 84, height: 84)
                                                    .clipped()
                                                    .cornerRadius(10)
                                            } else {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.15))
                                                    .frame(width: 84, height: 84)
                                                    .cornerRadius(10)
                                            }
                                            if !img.description.isEmpty {
                                                Image(systemName: "info.circle.fill")
                                                    .foregroundColor(.white)
                                                    .background(
                                                        Circle().fill(Color.blue).frame(width: 18, height: 18)
                                                    )
                                                    .padding(4)
                                            }
                                        }
                                        .onTapGesture {
                                            selectedImageContext = ImageViewerContext(note: note, images: note.images, initialIndex: idx)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                if notes.allSatisfy({ $0.images.isEmpty }) {
                    ZStack {
                        VStack {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                                .padding()
                            Text("No images in this section")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .padding(.top)
        }
        .fullScreenCover(item: $selectedImageContext) { context in
            ImageDetailView(
                note: context.note,
                image: context.images[context.initialIndex],
                images: context.images,
                initialIndex: context.initialIndex,
                onClose: { selectedImageContext = nil }
            )
            .environmentObject(noteManager)
        }
    }
}
