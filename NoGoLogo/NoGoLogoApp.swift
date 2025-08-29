import SwiftUI

@main
struct NoGoLogoApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(LogManager.shared)
        }
        .defaultSize(width: 600, height: 800)  // Base; dynamic frame in ContentView overrides on content load
    }
}
