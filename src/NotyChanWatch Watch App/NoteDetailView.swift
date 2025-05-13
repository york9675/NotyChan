import SwiftUI

struct NoteDetailView: View {
    let note: Note

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(note.title.isEmpty ? String(localized: "Untitled Note") : note.title)
                    .font(.system(size: 24, weight: .heavy))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .padding(.bottom, 2)
                if note.isLocked {
                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Locked note")
                            .bold()
                        Text("Unlock and view on your iPhone.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 80)
                } else {
                    Text(note.plainText)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                Text("Last edited: \(note.lastEditedFormatted)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
            .padding(.horizontal)
        }
        .navigationTitle("Note")
    }
}

private extension Note {
    var plainText: String {
        guard let attributed = try? NSAttributedString(data: rtfData, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
        else { return "" }
        return attributed.string
    }
    var lastEditedFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: lastEdited)
    }
}
