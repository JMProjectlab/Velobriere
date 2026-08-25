import SwiftUI
#if canImport(FirebaseFirestore)
import FirebaseCore
#endif

@main
struct VelobriereApp: App {
    init() {
        #if canImport(FirebaseFirestore)
        // Sans `GoogleService-Info.plist` dans le bundle, cet appel ne fait
        // rien : l'application démarre et fonctionne en local, comme avant.
        FirebaseSupport.configureIfPossible()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
    }
}
