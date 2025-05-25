import SwiftUI
import PhotosUI

struct GalleryView: View {
    @EnvironmentObject var noteManager: NoteManager
    @Environment(\.dismiss) var dismiss
    @State var note: Note
    
    @State private var showPhotosPicker = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImageContext: ImageViewerContext? = nil

    @State private var showCamera = false

    @State private var alertImageToDelete: NoteImage? = nil
    @State private var showDeleteAlert: Bool = false

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
                        Menu {
                            Button {
                                showCamera = true
                            } label: {
                                Label("Take Photo", systemImage: "camera")
                            }
                            
                            Button {
                                showPhotosPicker = true
                            } label: {
                                Label("Add from Library", systemImage: "photo.badge.plus")
                            }
                        } label: {
                            Label("Add", systemImage: "plus")
                                .font(.headline)
                        }
                        .photosPicker(isPresented: $showPhotosPicker, selection: $selectedItems, maxSelectionCount: nil, matching: .images)
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
                                        alertImageToDelete = image
                                        showDeleteAlert = true
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
                    Menu {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Take Photo", systemImage: "camera")
                        }
                        
                        Button {
                            showPhotosPicker = true
                        } label: {
                            Label("Add from Library", systemImage: "photo.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onChange(of: selectedItems) { _, newItems in
                guard !newItems.isEmpty else { return }
                Task {
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            _ = noteManager.saveImage(uiImage, for: note)
                        }
                    }
                    refreshNote()
                    selectedItems = []
                }
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
            // Present the camera
            .fullScreenCover(isPresented: $showCamera) {
                CameraView { image in
                    if let _ = noteManager.saveImage(image, for: note) {
                        refreshNote()
                    }
                }
            }
            .photosPicker(isPresented: $showPhotosPicker, selection: $selectedItems, maxSelectionCount: nil, matching: .images)
            // Delete confirmation alert
            .alert("Delete Image", isPresented: $showDeleteAlert, presenting: alertImageToDelete) { img in
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    noteManager.deleteImage(img, for: note)
                    refreshNote()
                }
            } message: { _ in
                Text("Are you sure you want to delete this image? This action cannot be undone.")
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

// Array safe subscript
extension Array {
    subscript(safe idx: Int) -> Element? {
        indices.contains(idx) ? self[idx] : nil
    }
}
