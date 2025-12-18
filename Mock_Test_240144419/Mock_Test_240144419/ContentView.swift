import SwiftUI
import SwiftData
import Foundation
struct ContentView: View {
    // Fetch all places, sorted by name
    @Query(sort: \Place.name) private var places: [Place]
    
    // For filter state
    @State private var selectedCategory: String = ""  // Empty = All
    @State private var showingFilterSheet: Bool = false
    
    // Computed: Unique categories for filter options
    private var uniqueCategories: [String] {
        Array(Set(places.map { $0.category })).sorted()
    }
    
    // Computed: Filtered list
    private var filteredPlaces: [Place] {
        if selectedCategory.isEmpty {
            return places
        } else {
            return places.filter { $0.category == selectedCategory }
        }
    }
    
    var body: some View {
        NavigationStack {  // IMPORTANT: Wrap everything in NavigationStack for navigation to work!
            List(filteredPlaces) { place in
                NavigationLink {
                    Details(place: place)
                } label: {
                    VStack(alignment: .leading) {
                        Text(place.name)
                            .font(.headline)
                        Text(place.category)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Location")  // Matches your screenshot
            .toolbar {
                // Left: Filter button (the "All" pill)
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingFilterSheet = true  // Open filter sheet
                    } label: {
                        Text(selectedCategory.isEmpty ? "All" : selectedCategory)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray5))  // Light gray pill background
                            .cornerRadius(20)  // Rounded pill shape
                            .foregroundColor(.primary)
                    }
                }
                
                // Right: + button to Insert
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        Insert()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)  // Nice blue +
                    }
                }
            }
            // Filter sheet (popup from bottom)
            .sheet(isPresented: $showingFilterSheet) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Select Category")
                        .font(.title2)
                        .bold()
                        .padding()
                    
                    // "All" option
                    Button("All") {
                        selectedCategory = ""
                        showingFilterSheet = false
                    }
                    .padding()
                    
                    // List of categories
                    ForEach(uniqueCategories, id: \.self) { category in
                        Button(category) {
                            selectedCategory = category
                            showingFilterSheet = false
                        }
                        .padding()
                    }
                    
                    Spacer()
                }
                .presentationDetents([.medium])  // Sheet not full screen
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Place.self)
}
