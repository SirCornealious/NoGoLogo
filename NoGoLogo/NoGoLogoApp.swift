//
//  NoGoLogoApp.swift
//  NoGoLogo
//
//  Created by Jared Maxwell on 8/26/25.
//

import SwiftUI

@main
struct NoGoLogoApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
