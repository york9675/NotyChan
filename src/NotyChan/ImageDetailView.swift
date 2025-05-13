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
                    TabView(selection: $currentIndex) {
                        ForEach(images.indices, id: \.self) { index in
                            if let uiImage = noteManager.loadImage(for: note, image: images[index]) {
                                ZoomableImageView(image: uiImage)
                                    .tag(index)
                            } else {
                                Color.gray
                                    .overlay(
                                        VStack {
                                            Image(systemName: "exclamationmark.triangle")
                                                .font(.largeTitle)
                                                .foregroundColor(.white)
                                            Text("Image not available")
                                                .foregroundColor(.white)
                                        }
                                    )
                                    .tag(index)
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
                }
            }

            // Top Bar
            VStack {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial.opacity(0.7))
                            .clipShape(Circle())
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
                                    .blur(radius: 0.5)
                            )
                            .shadow(radius: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    Spacer()
                    Color.clear.frame(width: 46, height: 1)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                Spacer()

                // Action toolbar
                VStack(alignment: .leading, spacing: 0) {
                    if !currentImage.description.isEmpty {
                        // Expand/collapse logic for description view
                        DescriptionExpandableView(
                            description: currentImage.description,
                            expanded: $showFullDescription
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showFullDescription.toggle()
                            }
                        }
                        .padding(.horizontal, 22)
                        .padding(.bottom, 10)
                        .transition(.opacity)
                    }

                    HStack(spacing: 48) {
                        Button {
                            editingDescription = currentImage.description
                            isEditingDescription = true
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 26, weight: .regular))
                                Text("Description")
                                    .font(.caption2)
                            }
                            .foregroundColor(.white)
                        }

                        Button {
                            deleteConfirmation = true
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.system(size: 26, weight: .regular))
                                Text("Delete")
                                    .font(.caption2)
                            }
                            .foregroundColor(.red)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    .padding(.bottom, 26)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.95),
                                Color.black.opacity(0.7),
                                Color.black.opacity(0.5)
                            ]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .sheet(isPresented: $isEditingDescription, onDismiss: {
            // Reload the note and images after editing
            if let updatedNote = noteManager.notes.first(where: { $0.id == note.id }) {
                // If you want the new images/descriptions to reflect immediately
                self.images = updatedNote.images
            }
        }) {
            NavigationView {
                Form {
                    Section("Description") {
                        // FIX: Remove minHeight/maxHeight to avoid NaN bug
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
                if images.count == 1 {
                    onClose()
                } else if currentIndex >= images.count - 1 {
                    currentIndex = max(0, currentIndex - 1)
                }
            }
        } message: {
            Text("Are you sure you want to delete this image? This action cannot be undone.")
        }
        .onChange(of: noteManager.notes) { _, _ in
            if currentIndex >= images.count { currentIndex = max(0, currentIndex - 1) }
        }
        // Collapse desc when switching images
        .onChange(of: currentIndex) { _, _ in
            showFullDescription = false
        }
    }

    private var currentImage: NoteImage {
        guard currentIndex < images.count else { return image }
        return images[currentIndex]
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
                            width: UIScreen.main.bounds.width - 110, // padding
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
                .fill(.ultraThinMaterial.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}

// Helper view to detect line limit exceeded in SwiftUI
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

// MARK: - ZoomableImageView

struct ZoomableImageView: View {
    let image: UIImage

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
                    scale = min(max(newScale, 1), 5)
                    offset = clampOffset(offset, scale: scale, imageSize: fittedImageSize, viewSize: size)
                }
                .onEnded { _ in
                    lastScale = scale
                    offset = clampOffset(offset, scale: scale, imageSize: fittedImageSize, viewSize: size)
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

            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size.width, height: size.height)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(magnification)
                // Attach drag gesture ONLY if zoomed in
                .simultaneousGesture(scale > 1 ? drag : nil)
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
                    }
                }
                .animation(.easeInOut(duration: 0.22), value: scale)
                .animation(.easeInOut(duration: 0.22), value: offset)
                .background(Color.black)
                .clipped()
        }
        .ignoresSafeArea()
        .onChange(of: image) { _, _ in
            scale = 1
            lastScale = 1
            offset = .zero
            lastOffset = .zero
        }
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
