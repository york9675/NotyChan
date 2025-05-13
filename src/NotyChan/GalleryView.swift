import SwiftUI
import PhotosUI

struct GalleryView: View {
    @EnvironmentObject var noteManager: NoteManager
    @Environment(\.dismiss) var dismiss
    @State var note: Note
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageContext: ImageViewerContext? = nil

    var body: some View {
        NavigationView {
            ZStack {
                if note.images.isEmpty {
                    VStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                            .padding()
                        Text("No images yet")
                            .font(.headline)
                        Text("Tap the plus button to add photos to this note.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        PhotosPicker(
                            selection: $selectedItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Label("Add photos", systemImage: "photo.badge.plus")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 8)], spacing: 8) {
                            ForEach(note.images.indices, id: \.self) { index in
                                let image = note.images[index]
                                ZStack(alignment: .bottomTrailing) {
                                    if let uiImage = noteManager.loadImage(for: note, image: image) {
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
                                    if !image.description.isEmpty {
                                        Image(systemName: "info.circle.fill")
                                            .foregroundColor(.white)
                                            .background(
                                                Circle().fill(Color.blue).frame(width: 18, height: 18)
                                            )
                                            .padding(4)
                                    }
                                }
                                .onTapGesture {
                                    selectedImageContext = ImageViewerContext(note: note, images: note.images, initialIndex: index)
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        noteManager.deleteImage(image, for: note)
                                        refreshNote()
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Gallery")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .bold()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Image(systemName: "photo.badge.plus")
                    }
                }
            }
            .onChange(of: selectedItem) { _, newValue in
                guard let item = newValue else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        _ = noteManager.saveImage(uiImage, for: note)
                        refreshNote()
                    }
                }
            }
            .sheet(item: $selectedImageContext) { context in
                ImageDetailView(
                    note: context.note,
                    image: context.images[context.initialIndex],
                    images: context.images,
                    initialIndex: context.initialIndex
                ) {
                    selectedImageContext = nil
                    refreshNote()
                }
                .environmentObject(noteManager)
                .interactiveDismissDisabled(true)
            }
        }
        .onAppear { refreshNote() }
        .onChange(of: noteManager.notes) { _, _ in refreshNote() }
    }

    private func refreshNote() {
        if let updated = noteManager.notes.first(where: { $0.id == note.id }) {
            note = updated
        }
    }
}

// Array safe subscript (as before)
extension Array {
    subscript(safe idx: Int) -> Element? {
        indices.contains(idx) ? self[idx] : nil
    }
}
