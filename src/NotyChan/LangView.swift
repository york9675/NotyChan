import SwiftUI

struct LangView: View {
    private var isMacOS: Bool {
        #if targetEnvironment(macCatalyst)
        return true
        #else
        return false
        #endif
    }
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .center) {
                    Image(systemName: "globe")
                        .resizable()
                        .foregroundStyle(.yellow)
                        .frame(width: 30, height: 30)
                        .aspectRatio(contentMode: .fit)
                        .padding(.bottom, 8)
                    
                    Text("Language")
                        .font(.title3)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 8)
                    
                    if !isMacOS {
                        Text("Please click the button below to jump to the system settings and tap \"Language\" to change your preferred App language.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Please go to System Settings > General > Language & Region, scroll to the Applications section, and click Add (+). In the dialog, select this app from the app list, choose your preferred language from the dropdown menu, and click Add. Restart this app to apply the new language setting.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                    }
                    
                }
                .padding()
                .frame(maxWidth: .infinity)
                
                if !isMacOS {
                    Button(action: {
                        let url = URL(string: UIApplication.openSettingsURLString)!
                        UIApplication.shared.open(url)
                    }) {
                        Label("App Settings", systemImage: "gear")
                    }
                }
            }
        }
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
    }
}
