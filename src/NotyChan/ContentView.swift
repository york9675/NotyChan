import SwiftUI

struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject var noteManager = NoteManager()

    var body: some View {
        FolderListView()
            .tint(.yellow)
            .preferredColorScheme(themeManager.selectedTheme.colorScheme())
            .environmentObject(noteManager)
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
}
