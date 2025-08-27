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
                        HStack {
                            Label("All Notes", systemImage: "note.text")
                            Spacer()
                            Text("\(wcManager.allNotes.count)")
                                .foregroundColor(.secondary)
                                .font(.footnote)
                        }
                    }
                }

                Section(header: Text("Folders")) {
                    ForEach(wcManager.folders) { folder in
                        NavigationLink {
                            NoteListView(folder: folder)
                        } label: {
                            HStack {
                                Label(folder.name, systemImage: "folder")
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
                
                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        HStack {
                            Label("About", systemImage: "info.circle")
                        }
                    }
                }
            }
            .navigationTitle("Folders")
        }
    }
}
