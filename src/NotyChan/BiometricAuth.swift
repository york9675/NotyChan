import Foundation
import LocalAuthentication

enum BiometricAuth {
    static func authenticate(reason: String = "Unlock your note") async -> Bool {
        let context = LAContext()
        var error: NSError?
        // Use deviceOwnerAuthentication to allow passcode fallback!
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }
        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}
