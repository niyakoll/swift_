//
//  Mock_Test_240144419App.swift
//  Mock_Test_240144419
//
//  Created by user on 17/12/2025.
//

import SwiftUI
import SwiftData
import Foundation
@main
struct Mock_Test_240144419App: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Place.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
