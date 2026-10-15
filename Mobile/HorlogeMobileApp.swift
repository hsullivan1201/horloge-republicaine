import SwiftUI

@main
struct HorlogeMobileApp: App {
    init() {
        AppGroup.migrate()
        let language = Locale.current.language.languageCode?.identifier == "fr"
            ? Language.fr.rawValue
            : Language.en.rawValue
        AppGroup.defaults.register(defaults: [
            "language": language,
            "appearance": Appearance.auto.rawValue,
            "chime": true,
        ])
        ChimeController.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            MobileRootView()
        }
    }
}
