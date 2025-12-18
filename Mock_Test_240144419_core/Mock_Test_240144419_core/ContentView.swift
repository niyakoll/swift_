//
//  ContentView.swift
//  Mock_Test_240144419
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Explicit entity fetch to avoid "must have an entity" error
    @FetchRequest(
        entity: Place.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Place.name, ascending: true)],
        animation: .default)
    private var places: FetchedResults<Place>
    
    @State private var selectedCategory: String = ""
    @State private var showingFilterSheet = false
    
    private var uniqueCategories: [String] {
        Array(Set(places.compactMap { $0.category })).sorted()
    }
    
    private var filteredPlaces: [Place] {
        if selectedCategory.isEmpty {
            return Array(places)
        } else {
            return places.filter { $0.category == selectedCategory }
        }
    }
    
    var body: some View {
        NavigationView {
            List(filteredPlaces) { place in
                NavigationLink(destination: Details(place: place)) {
                    VStack(alignment: .leading) {
                        Text(place.name ?? "No Name")
                            .font(.headline)
                        Text(place.category ?? "No Category")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Location")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingFilterSheet = true
                    } label: {
                        Text(selectedCategory.isEmpty ? "All" : selectedCategory)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray5))
                            .cornerRadius(20)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: Insert()) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                VStack(spacing: 20) {
                    Text("Select Category")
                        .font(.title2)
                        .bold()
                        .padding()
                    
                    Button("All") {
                        selectedCategory = ""
                        showingFilterSheet = false
                    }
                    .padding()
                    
                    ForEach(uniqueCategories, id: \.self) { category in
                        Button(category) {
                            selectedCategory = category
                            showingFilterSheet = false
                        }
                        .padding()
                    }
                    
                    Spacer()
                }
                .presentationDetents([.medium])
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
