import Foundation
import WatchConnectivity
import SwiftUI

class WatchSyncManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var notes: [Note] = []
    @Published var folders: [Folder] = []
    @Published var isSyncing = false

    override init() {
        super.init()
        activateSession()
    }

    // Sync helpers
    var allNotes: [Note] { notes.filter { !$0.isDeleted } }
    var deletedNotes: [Note] { notes.filter { $0.isDeleted } }

    func notes(in folderId: UUID) -> [Note] {
        notes.filter { $0.folderId == folderId && !$0.isDeleted }
    }

    // WCSession
    private func activateSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func requestSyncIfNeeded() {
        if notes.isEmpty || folders.isEmpty {
            requestSync()
        }
    }

    func requestSync() {
        guard WCSession.default.isReachable else { return }
        isSyncing = true
        WCSession.default.sendMessage(["request": "sync"], replyHandler: { reply in
            DispatchQueue.main.async {
                self.isSyncing = false
                self.decodeSyncPayload(reply)
            }
        }, errorHandler: { err in
            DispatchQueue.main.async { self.isSyncing = false }
        })
    }

    // WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let foldersData = message["folders"] as? Data,
           let notesData = message["notes"] as? Data {
            DispatchQueue.main.async {
                self.decodeSyncPayload(["folders": foldersData, "notes": notesData])
            }
        }
    }
    func sessionReachabilityDidChange(_ session: WCSession) {}

    private func decodeSyncPayload(_ payload: [String: Any]) {
        if let foldersData = payload["folders"] as? Data,
           let notesData = payload["notes"] as? Data {
            if let folders = try? JSONDecoder().decode([Folder].self, from: foldersData),
               let notes = try? JSONDecoder().decode([Note].self, from: notesData) {
                self.folders = folders
                self.notes = notes
            }
        }
    }
}
