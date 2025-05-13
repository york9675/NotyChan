import Foundation
import WatchConnectivity

class WatchSyncPush: NSObject {
    static let shared = WatchSyncPush()
    private override init() {
        super.init()
        activateSession()
    }

    func activateSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func pushAll(folders: [Folder], notes: [Note]) {
        guard WCSession.default.isPaired, WCSession.default.isWatchAppInstalled else { return }
        let encoder = JSONEncoder()
        guard let foldersData = try? encoder.encode(folders),
              let notesData = try? encoder.encode(notes) else { return }

        let payload: [String: Any] = [
            "folders": foldersData,
            "notes": notesData
        ]
        WCSession.default.transferCurrentComplicationUserInfo(payload)
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        }
    }
}

extension WatchSyncPush: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        // Watch requests sync
        if message["request"] as? String == "sync" {
            let encoder = JSONEncoder()
            let foldersData = try? encoder.encode(NoteManager().folders)
            let notesData = try? encoder.encode(NoteManager().notes)
            replyHandler([
                "folders": foldersData ?? Data(),
                "notes": notesData ?? Data()
            ])
        }
    }
}
