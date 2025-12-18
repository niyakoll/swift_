//
//  Insert.swift
//  Mock_Test_240144419
//
//  Created by user on 17/12/2025.
//

import Foundation
import SwiftUI
import SwiftData

// Insert Page view.
struct Insert: View {
    // State for input fields, like form state in React.
    @State private var name: String = ""
    @State private var category: String = ""
    @State private var description: String = ""
    @State private var latitude: String = ""
    @State private var longitude: String = ""
    
    // DB context for insert.
    @Environment(\.modelContext) var modelContext
    
    // To dismiss (go back), like navigation.pop in React Native.
    @Environment(\.dismiss) var dismiss
    
    // Body.
    var body: some View {
        VStack(spacing: 20) {
            // Text fields with hints (placeholders like in HTML input).
            TextField("Name", text: $name)
            TextField("Category", text: $category)
            TextField("Description", text: $description)
            TextField("Latitude", text: $latitude)
            TextField("Longitude", text: $longitude)
            
            // Buttons.
            HStack {
                Button("Save") {
                    // Comments: This method saves the new place to DB.
                    // Logic: Convert lat/long to Double (or default to 0 if invalid, to avoid crash).
                    let lat = Double(latitude) ?? 0.0
                    let lon = Double(longitude) ?? 0.0
                    // Create new Place.
                    let newPlace = Place(id:UUID(), name: name, category: category, place_description: description, lat: lat, lng: lon)
                    // Insert to DB, like SQL INSERT.
                    modelContext.insert(newPlace)
                    // Go back.
                    dismiss()
                }
                
                Button("Cancel") {
                    // Comments: This method cancels and returns to List Page without saving.
                    dismiss()
                }
            }
        }
        .padding()
        .navigationTitle("Insert Place")
    }
}

#Preview {
    Insert()
        .modelContainer(for: Place.self)
}
