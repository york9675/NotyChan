import SwiftUI

struct NoteListView: View {
    @EnvironmentObject var wcManager: WatchSyncManager
    let folder: Folder?

    var pinnedNotes: [Note] {
        filteredNotes.filter { $0.isPinned }
            .sorted(by: { $0.lastEdited > $1.lastEdited })
    }
    var unpinnedNotes: [Note] {
        filteredNotes.filter { !$0.isPinned }
            .sorted(by: { $0.lastEdited > $1.lastEdited })
    }
    var filteredNotes: [Note] {
        let all = folder == nil
            ? wcManager.allNotes
            : wcManager.notes(in: folder!.id)
        return all
    }

    var body: some View {
        List {
            if !pinnedNotes.isEmpty {
                Section(header: Label("Pinned", systemImage: "pin.fill")) {
                    ForEach(pinnedNotes) { note in
                        NavigationLink(destination: NoteDetailView(note: note)) {
                            NoteRow(note: note)
                        }
                    }
                }
            }
            Section {
                ForEach(unpinnedNotes) { note in
                    NavigationLink(destination: NoteDetailView(note: note)) {
                        NoteRow(note: note)
                    }
                }
            }
        }
        .navigationTitle(folder?.name ?? String(localized: "All Notes"))
    }
}

struct NoteRow: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(note.title.isEmpty ? String(localized: "Untitled Note") : note.title)
                    .font(.headline)
                    .lineLimit(1)
                if note.isLocked {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            if note.isLocked {
                Text("Locked note")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } else {
                Text(note.firstLine)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Text(note.lastEditedFormatted)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 2)
    }
}

private extension Note {
    var firstLine: String {
        guard let attributed = try? NSAttributedString(data: rtfData, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
        else { return "" }
        let all = attributed.string
        let lines = all.components(separatedBy: .newlines)
        return lines.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0 != title })
        ?? String(localized: "No additional text")
    }
    var lastEditedFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: lastEdited)
    }
}
