//
//  Insert.swift
//  Mock_Test_240144419
//

import SwiftUI
import CoreData

struct Insert: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var category: String = ""
    @State private var description: String = ""
    @State private var latitude: String = ""
    @State private var longitude: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Name", text: $name)
            TextField("Category", text: $category)
            TextField("Description", text: $description)
            TextField("Latitude", text: $latitude)
                .keyboardType(.decimalPad)
            TextField("Longitude", text: $longitude)
                .keyboardType(.decimalPad)
            
            HStack {
                Button("Save") {
                    let lat = Double(latitude) ?? 0.0
                    let lon = Double(longitude) ?? 0.0
                    
                    guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
                        return
                    }
                    
                    let newPlace = Place(context: viewContext)
                    newPlace.id = UUID()
                    newPlace.name = name
                    newPlace.category = category.isEmpty ? nil : category
                    newPlace.place_description = description
                    newPlace.lat = lat
                    newPlace.lng = lon
                    
                    do {
                        try viewContext.save()
                        dismiss()
                    } catch {
                        print("Save error: \(error)")
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .navigationTitle("Insert Place")
    }
}

#Preview {
    Insert()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
