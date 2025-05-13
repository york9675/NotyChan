import SwiftUI

struct MoveToFolderView: View {
    @EnvironmentObject var noteManager: NoteManager
    @Environment(\.dismiss) var dismiss

    let note: Note

    @State private var isAddingFolder = false
    @State private var newFolderName = String(localized: "New Folder")

    var body: some View {
        NavigationView {
            List {
                Button {
                    noteManager.moveNote(note, toFolder: nil)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "note.text")
                        Text("All Notes")
                    }
                }

                Section("Folders") {
                    ForEach(noteManager.folders) { folder in
                        Button {
                            noteManager.moveNote(note, toFolder: folder.id)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "folder")
                                Text(folder.name)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Move to Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        isAddingFolder = true
                        newFolderName = String(localized: "New Folder")
                    }) {
                        Image(systemName: "folder.badge.plus")
                    }
                    .accessibilityLabel("Add Folder")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("New Folder", isPresented: $isAddingFolder) {
                TextField("Folder Name", text: $newFolderName)
                Button("Cancel", role: .cancel) { }
                Button("Create") {
                    let name = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !name.isEmpty {
                        noteManager.addFolder(name: name)
                    }
                }
            }
        }
    }
}
