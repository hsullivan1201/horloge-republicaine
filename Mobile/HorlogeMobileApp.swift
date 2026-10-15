import SwiftUI

@main
struct HorlogeMobileApp: App {
    init() {
        let language = Locale.current.language.languageCode?.identifier == "fr"
            ? Language.fr.rawValue
            : Language.en.rawValue
        UserDefaults.standard.register(defaults: [
            "language": language,
            "chime": true,
        ])
        ChimeController.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            MobileRootView()
                .preferredColorScheme(.light)
        }
    }
}
