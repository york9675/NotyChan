import SwiftUI

struct FolderListView: View {
    @EnvironmentObject var wcManager: WatchSyncManager

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    NavigationLink {
                        NoteListView(folder: nil)
                    } label: {
                        Label("All Notes (\(wcManager.allNotes.count))", systemImage: "note.text")
                    }
                }

                Section(header: Text("Folders")) {
                    ForEach(wcManager.folders) { folder in
                        NavigationLink {
                            NoteListView(folder: folder)
                        } label: {
                            HStack {
                                Image(systemName: "folder")
                                    .foregroundColor(.accentColor)
                                Text(folder.name)
                                Spacer()
                                Text("\(wcManager.notes(in: folder.id).count)")
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: { wcManager.requestSync() }) {
                        Label(wcManager.isSyncing ? "Syncing…" : "Sync Now", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(wcManager.isSyncing)
                }
            }
            .navigationTitle("Folders")
        }
    }
}
