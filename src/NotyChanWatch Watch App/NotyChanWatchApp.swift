import SwiftUI

@main
struct NotyChanWatch_Watch_AppApp: App {
    @StateObject private var wcManager = WatchSyncManager()
    
    init() {
        print(#"""
                            _            
            |\ |  _ _|_    /  |_   _. ._ 
            | \| (_) |_ \/ \_ | | (_| | | for watchOS
                        /         
            
            Welcome to the NotyChan by York!
                    
            If you like this app, please leave a star on the GitHub project page, or consider sponsoring me through Buy Me a Coffee!
            Encounter any problems during use? Please create GitHub Issues to report!
            
            © 2025 York Development
            
            ========== HAVE A NICE DAY! ==========
            """#)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(wcManager)
        }
    }
}
