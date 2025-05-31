import SwiftUI

struct ImageDetailView: View {
    @EnvironmentObject var noteManager: NoteManager
    @Environment(\.dismiss) var dismiss
    let note: Note
    let image: NoteImage
    let initialIndex: Int
    let onClose: () -> Void

    @State private var currentIndex: Int
    @State private var editingDescription = ""
    @State private var isEditingDescription = false
    @State private var deleteConfirmation = false
    @State private var showFullDescription = false
    @State var images: [NoteImage]
    @State private var isZoomed: Bool = false
    @State private var showActionMenu = false

    init(note: Note, image: NoteImage, images: [NoteImage], initialIndex: Int, onClose: @escaping () -> Void) {
        self.note = note
        self.image = image
        self.images = images
        self.initialIndex = initialIndex
        self.onClose = onClose
        _currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geometry in
                if !images.isEmpty {
                    ZStack {
                        ZoomableImageView(
                            image: noteManager.loadImage(for: note, image: currentImage) ?? UIImage(),
                            isZoomed: $isZoomed,
                            onSwipeDownToClose: {
                                if !isZoomed {
                                    onClose()
                                }
                            },
                            enableSwipeDown: !isZoomed
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .transition(.opacity)

                        if images.count > 1 && !isZoomed {
                            HStack {
                                Color.clear
                                    .contentShape(Rectangle())
                                    .frame(width: geometry.size.width * 0.3)
                                    .onTapGesture {
                                        if currentIndex > 0 { currentIndex -= 1 }
                                    }
                                Spacer()
                                Color.clear
                                    .contentShape(Rectangle())
                                    .frame(width: geometry.size.width * 0.3)
                                    .onTapGesture {
                                        if currentIndex < images.count - 1 { currentIndex += 1 }
                                    }
                            }
                        }
                    }
                }
            }

            VStack {
                // Top bar
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial.opacity(0.7))
                            .clipShape(Circle())
                            .shadow(radius: 4)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }

                    Spacer()
                    
                    if images.count > 1 {
                        Text("\(currentIndex + 1) / \(images.count)")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial.opacity(0.7))
                            )
                            .shadow(radius: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }

                    Spacer()

                    Menu {
                        Button {
                            editingDescription = currentImage.description
                            isEditingDescription = true
                        } label: {
                            Label("Edit Description", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            deleteConfirmation = true
                        } label: {
                            Label("Delete Image", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial.opacity(0.7))
                            .clipShape(Circle())
                            .shadow(radius: 4)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Spacer()

                HStack(alignment: .bottom) {
                    if !currentImage.description.isEmpty {
                        DescriptionExpandableView(
                            description: currentImage.description,
                            expanded: $showFullDescription
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showFullDescription.toggle()
                            }
                        }
                        .padding(.leading, 22)
                        .padding(.bottom, 30)
                    }
                    Spacer()
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .sheet(isPresented: $isEditingDescription, onDismiss: {
            if let updatedNote = noteManager.notes.first(where: { $0.id == note.id }) {
                self.images = updatedNote.images
            }
        }) {
            NavigationView {
                Form {
                    Section("Description") {
                        TextEditor(text: $editingDescription)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.vertical, 4)
                            .textInputAutocapitalization(.sentences)
                    }
                }
                .navigationTitle("Edit Description")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isEditingDescription = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            noteManager.updateImageDescription(currentImage, for: note, newDescription: editingDescription)
                            isEditingDescription = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .alert("Delete Image", isPresented: $deleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                noteManager.deleteImage(currentImage, for: note)
                onClose()
            }
        } message: {
            Text("Are you sure you want to delete this image? This action cannot be undone.")
        }
        .onChange(of: noteManager.notes) { _, _ in
            if currentIndex >= images.count { currentIndex = max(0, currentIndex - 1) }
        }
        .onChange(of: currentIndex) { _, _ in
            showFullDescription = false
        }
    }

    private var currentImage: NoteImage {
        guard currentIndex < images.count else { return image }
        return images[currentIndex]
    }
}

// MARK: - ZoomableImageView

struct ZoomableImageView: View {
    let image: UIImage
    @Binding var isZoomed: Bool
    var onSwipeDownToClose: () -> Void
    var enableSwipeDown: Bool

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let imageAspect = image.size.width / max(image.size.height, 1)
            let viewAspect = size.width / max(size.height, 1)
            let fittedImageSize: CGSize = {
                if imageAspect > viewAspect {
                    let width = size.width
                    let height = width / imageAspect
                    return CGSize(width: width, height: height)
                } else {
                    let height = size.height
                    let width = height * imageAspect
                    return CGSize(width: width, height: height)
                }
            }()

            let magnification = MagnificationGesture()
                .onChanged { value in
                    let newScale = lastScale * value
                    let clamped = min(max(newScale, 1), 5)
                    scale = clamped
                    isZoomed = scale > 1.01
                    offset = clampOffset(offset, scale: scale, imageSize: fittedImageSize, viewSize: size)
                }
                .onEnded { _ in
                    lastScale = scale
                    offset = clampOffset(offset, scale: scale, imageSize: fittedImageSize, viewSize: size)
                    isZoomed = scale > 1.01
                }

            let drag = DragGesture()
                .onChanged { value in
                    guard scale > 1 else { return }
                    let raw = CGSize(width: lastOffset.width + value.translation.width,
                                     height: lastOffset.height + value.translation.height)
                    offset = clampOffset(raw, scale: scale, imageSize: fittedImageSize, viewSize: size)
                }
                .onEnded { _ in
                    lastOffset = offset
                }

            let swipeToClose = DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
                    guard enableSwipeDown, abs(value.translation.height) > abs(value.translation.width), value.translation.height > 60 else { return }
                    onSwipeDownToClose()
                }

            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size.width, height: size.height)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(magnification)
                .simultaneousGesture(scale > 1 ? drag : nil)
                .simultaneousGesture(enableSwipeDown ? swipeToClose : nil)
                .onTapGesture(count: 2) {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        if scale > 1 {
                            scale = 1
                            lastScale = 1
                            offset = .zero
                            lastOffset = .zero
                        } else {
                            scale = 2
                            lastScale = 2
                            offset = .zero
                            lastOffset = .zero
                        }
                        isZoomed = scale > 1.01
                    }
                }
                .animation(.easeInOut(duration: 0.22), value: scale)
                .animation(.easeInOut(duration: 0.22), value: offset)
                .background(Color.black)
                .clipped()
        }
        .ignoresSafeArea()
    }

    private func clampOffset(_ raw: CGSize, scale: CGFloat, imageSize: CGSize, viewSize: CGSize) -> CGSize {
        guard scale > 1 else { return .zero }
        let scaled = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let maxOffsetX = max(0, (scaled.width - viewSize.width) / 2)
        let maxOffsetY = max(0, (scaled.height - viewSize.height) / 2)
        let clampedX = min(max(raw.width, -maxOffsetX), maxOffsetX)
        let clampedY = min(max(raw.height, -maxOffsetY), maxOffsetY)
        return CGSize(width: clampedX, height: clampedY)
    }
}


// MARK: - DescriptionExpandableView

struct DescriptionExpandableView: View {
    let description: String
    @Binding var expanded: Bool

    // For line limit detection
    @State private var exceeded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.white)
                Text(description)
                    .font(.body)
                    .foregroundColor(.white)
                    .lineLimit(expanded ? nil : 1)
                    .truncationMode(.tail)
                    .padding(.vertical, 6)
                    .background(
                        TextLineLimitDetector(
                            text: description,
                            font: .body,
                            width: UIScreen.main.bounds.width - 110,
                            lineLimit: 1,
                            exceeded: $exceeded
                        )
                        .frame(width: 0, height: 0)
                        .opacity(0)
                    )
                if exceeded && !expanded {
                    Image(systemName: "chevron.down")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 15, weight: .semibold))
                } else if exceeded && expanded {
                    Image(systemName: "chevron.up")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 15, weight: .semibold))
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}

// Helper view to detect line limit exceeded
struct TextLineLimitDetector: UIViewRepresentable {
    let text: String
    let font: UIFont.TextStyle
    let width: CGFloat
    let lineLimit: Int
    @Binding var exceeded: Bool

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: font)
        label.numberOfLines = lineLimit
        label.lineBreakMode = .byTruncatingTail
        label.text = text
        return label
    }
    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.text = text
        uiView.font = UIFont.preferredFont(forTextStyle: font)
        uiView.numberOfLines = lineLimit
        uiView.preferredMaxLayoutWidth = width

        // Detect if line limit is exceeded
        let textRect = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: uiView.font!],
            context: nil
        )
        let oneLineHeight = "A".boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: uiView.font!],
            context: nil
        ).height
        let lines = Int((textRect.height / oneLineHeight).rounded(.up))
        DispatchQueue.main.async {
            self.exceeded = lines > lineLimit
        }
    }
}
