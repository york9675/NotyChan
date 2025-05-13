import SwiftUI

struct ContentView: View {
    @EnvironmentObject var wcManager: WatchSyncManager
    
    var body: some View {
        NavigationStack {
            if wcManager.isSyncing {
                ProgressView("Syncing…")
            } else if wcManager.folders.isEmpty && wcManager.notes.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                        .padding(.bottom, 2)
                    Text("No notes. Open the app on your iPhone to sync.")
                        .multilineTextAlignment(.center)
                        .font(.footnote)
                    Button(action: {
                        wcManager.requestSync()
                    }) {
                        Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                .padding()
            } else {
                FolderListView()
            }
        }
        .onAppear { wcManager.requestSyncIfNeeded() }
    }
}

#Preview {
    ContentView()
}
