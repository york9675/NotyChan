import Foundation
import SwiftUI

// Enum for themes
enum Theme: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark

    var id: String { self.rawValue }

    var localizedString: String {
        switch self {
        case .system:
            return String(localized: "System")
        case .light:
            return String(localized: "Light")
        case .dark:
            return String(localized: "Dark")
        }
    }

    func colorScheme() -> ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

class ThemeManager: ObservableObject {
    @Published var selectedTheme: Theme {
        didSet {
            saveTheme(selectedTheme)
        }
    }
    
    private static let themeKey = "notychan_selected_theme"
    
    init() {
        if let saved = Self.loadTheme() {
            selectedTheme = saved
        } else {
            selectedTheme = .system
        }
    }
    
    private func saveTheme(_ theme: Theme) {
        UserDefaults.standard.set(theme.rawValue, forKey: Self.themeKey)
    }
    
    private static func loadTheme() -> Theme? {
        if let raw = UserDefaults.standard.string(forKey: themeKey),
           let theme = Theme(rawValue: raw) {
            return theme
        }
        return nil
    }
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var noteManager: NoteManager
    
    let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"

    var body: some View {
        NavigationView {
            Form {
                // General Section
                Section(header: Text("General")) {
                    Picker(selection: $themeManager.selectedTheme, label: Label("Theme", systemImage: "moon")) {
                        ForEach(Theme.allCases) { theme in
                            Text(theme.localizedString).tag(theme)
                        }
                    }
                    
                    NavigationLink(destination: LangView()) {
                        Label("Language", systemImage: "globe")
                    }
                }

                // About Section
                Section(header: Text("About"), footer: Text("© 2025 York Development")) {
                    NavigationLink(destination: AcknowledgementsView()) {
                        Label("Acknowledgements", systemImage: "doc.text")
                    }
                    
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("\(appVersion) (\(buildNumber))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Done")
                            .bold()
                    }
                }
            }
        }
    }
}
