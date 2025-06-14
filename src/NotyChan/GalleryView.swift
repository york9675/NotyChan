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

    @State private var isSelecting = false
    @State private var selectedImageIDs = Set<UUID>()
    @State private var showBatchDeleteAlert = false

    private var allSelected: Bool {
        !note.images.isEmpty && selectedImageIDs.count == note.images.count
    }
    private var noneSelected: Bool {
        selectedImageIDs.isEmpty
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Main gallery
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
                                ZStack(alignment: .bottomLeading) {
                                    if let uiImage = noteManager.loadImage(for: note, image: image) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 84, height: 84)
                                            .clipped()
                                            .cornerRadius(10)
                                            .overlay(
                                                Group {
                                                    if isSelecting {
                                                        Color.black.opacity(selectedImageIDs.contains(image.id) ? 0.3 : 0.15)
                                                            .cornerRadius(10)
                                                        VStack {
                                                            Spacer()
                                                            HStack {
                                                                Image(systemName: selectedImageIDs.contains(image.id) ? "checkmark.circle.fill" : "circle")
                                                                    .font(.system(size: 22))
                                                                    .foregroundColor(selectedImageIDs.contains(image.id) ? .accentColor : .white.opacity(0.8))
                                                                Spacer()
                                                            }
                                                            .padding(6)
                                                        }
                                                    }
                                                }
                                            )
                                            .onTapGesture {
                                                if isSelecting {
                                                    if selectedImageIDs.contains(image.id) {
                                                        selectedImageIDs.remove(image.id)
                                                    } else {
                                                        selectedImageIDs.insert(image.id)
                                                    }
                                                } else {
                                                    selectedImageContext = ImageViewerContext(note: note, images: note.images, initialIndex: index)
                                                }
                                            }
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
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                    }
                                }
                                .contextMenu {
                                    if !isSelecting {
                                        Button(role: .destructive) {
                                            alertImageToDelete = image
                                            showDeleteAlert = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                } preview: {
                                    if let uiImage = noteManager.loadImage(for: note, image: image) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                    }
                                }
                            }
                        }
                        .padding(.top)
                    }
                }

                // Selection action bar
                if isSelecting && !note.images.isEmpty {
                    VStack {
                        Spacer()
                        HStack(spacing: 0) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    if noneSelected || !allSelected {
                                        Button {
                                            selectedImageIDs = Set(note.images.map(\.id))
                                        } label: {
                                            Label("Select All", systemImage: "checkmark.circle")
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                    if allSelected {
                                        Button {
                                            selectedImageIDs.removeAll()
                                        } label: {
                                            Label("Deselect All", systemImage: "circle")
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                    if note.images.count > 0 {
                                        if allSelected || !noneSelected {
                                            Button(role: .destructive) {
                                                showBatchDeleteAlert = true
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                            .buttonStyle(.bordered)
                                            .tint(.red)
                                        }
                                        if noneSelected {
                                            Button(role: .destructive) {
                                                showBatchDeleteAlert = true
                                            } label: {
                                                Label("Delete All", systemImage: "trash")
                                            }
                                            .buttonStyle(.bordered)
                                            .tint(.red)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                                .padding(.leading)
                            }
                        }
                        .background(.regularMaterial)
                    }
                }
            }
            .navigationTitle(
                isSelecting
                    ? (selectedImageIDs.isEmpty ? "Select Images" : "\(selectedImageIDs.count) Selected")
                    : "Gallery"
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .bold()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        if !note.images.isEmpty {
                            Button(isSelecting ? "Done" : "Select") {
                                isSelecting.toggle()
                                if !isSelecting {
                                    selectedImageIDs.removeAll()
                                }
                            }
                        }
                        if !isSelecting {
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
            .fullScreenCover(isPresented: $showCamera) {
                CameraView { image in
                    if let _ = noteManager.saveImage(image, for: note) {
                        refreshNote()
                    }
                }
            }
            .photosPicker(isPresented: $showPhotosPicker, selection: $selectedItems, maxSelectionCount: nil, matching: .images)
            .alert("Delete Image", isPresented: $showDeleteAlert, presenting: alertImageToDelete) { img in
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    noteManager.deleteImage(img, for: note)
                    refreshNote()
                }
            } message: { _ in
                Text("Are you sure you want to delete this image? This action cannot be undone.")
            }
            .alert("Delete Selected Images", isPresented: $showBatchDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    let idsToDelete = noneSelected ? note.images.map(\.id) : Array(selectedImageIDs)
                    for id in idsToDelete {
                        if let img = note.images.first(where: { $0.id == id }) {
                            noteManager.deleteImage(img, for: note)
                        }
                    }
                    refreshNote()
                    selectedImageIDs.removeAll()
                    isSelecting = false
                }
            } message: {
                Text("Are you sure you want to delete the selected \(noneSelected ? note.images.count : selectedImageIDs.count) images? This action cannot be undone.")
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
