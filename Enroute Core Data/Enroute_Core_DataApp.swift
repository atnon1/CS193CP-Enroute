//
//  Enroute_Core_DataApp.swift
//  Enroute Core Data
//
//  Created by Anton Makeev on 21.01.2021.
//

import SwiftUI

@main
struct Enroute_Core_DataApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
