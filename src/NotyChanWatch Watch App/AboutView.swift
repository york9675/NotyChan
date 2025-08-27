import SwiftUI

struct AboutView: View {
        private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }
    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {                
                // Title
                Text("NotyChan")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                
                // Description
                Text("NotyChan is a beautiful, lightweight, and privacy-respecting note-taking app for iOS, iPadOS and macOS.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
                Divider().padding(.vertical, 4)
                
                // Details
                VStack(alignment: .leading, spacing: 6) {
                    infoRow(title: String(localized: "Developer"), value: String(localized: "York"))
                    
                    infoRow(
                        title: String(localized: "Version"),
                        value: "\(appVersion) (\(buildNumber))",
                        accessibilityLabel: "Version \(appVersion), build \(buildNumber)"
                    )
                    
                    // Copyright
                    Text("© 2025 York Development")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("© 2025 York Development")
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .navigationTitle("About")
        }
    }
    
    @ViewBuilder
    private func infoRow(title: String, value: String, accessibilityLabel: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value)
                .font(.caption)
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel ?? "\(title): \(value)")
    }
}
