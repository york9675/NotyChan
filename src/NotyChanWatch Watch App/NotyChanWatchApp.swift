import SwiftUI

@main
struct NotyChanWatch_Watch_AppApp: App {
    @StateObject private var wcManager = WatchSyncManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(wcManager)
        }
    }
}
