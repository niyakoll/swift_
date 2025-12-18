//
//  Mock_Test_240144419App.swift
//  Mock_Test_240144419
//

import SwiftUI
import CoreData
@main
struct Mock_Test_240144419App_core: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Sample data for preview
        let sample = Place(context: viewContext)
        sample.id = UUID()
        sample.name = "Tokyo Tower"
        sample.category = "Sightseeing"
        sample.place_description = "Famous tower in Tokyo"
        sample.lat = 35.6586
        sample.lng = 139.7454
        
        do { try viewContext.save() } catch { fatalError("Preview save failed") }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Mock_Test_240144419_core")  // Must match your .xcdatamodeld name
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data load failed: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
