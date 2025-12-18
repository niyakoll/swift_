import SwiftUI
import MapKit
import SwiftData
import Foundation
struct Details: View {
    let place: Place
    
    // We need to control the map position
    @State private var region: MKCoordinateRegion
    
    init(place: Place) {
        self.place = place
        
        // Set initial map center and zoom level
        let center = CLLocationCoordinate2D(latitude: place.lat, longitude: place.lng)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let initialRegion = MKCoordinateRegion(center: center, span: span)
        
        // Initialize the @State property correctly
        self._region = State(initialValue: initialRegion)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Name: \(place.name)")
            Text("Description: \(place.place_description)")
            Text("Latitude: \(place.lat)")
            Text("Longitude: \(place.lng)")
            
            // CORRECT MAP SYNTAX for iOS 17+
            Map(initialPosition: .region(region)) {
                Marker(
                    place.name,
                    coordinate: CLLocationCoordinate2D(
                        latitude: place.lat,
                        longitude: place.lng
                    )
                )
            }
            .frame(height: 300)
            .mapStyle(.standard)   // Optional: normal map look
            
            Spacer()
            Button("Back") {
                // NavigationStack handles back automatically
            }
        }
        .padding()
        .navigationTitle("Place Details")
    }
}

// FIXED PREVIEW — No more brace error!
#Preview {
    let previewPlace = Place(
        id:UUID(),
        name: "Tokyo Tower",
        category: "Sightseeing",
        place_description: "A famous red and white tower in Tokyo with amazing views.",
        lat: 35.6586,
        lng: 139.7454
    )
    
    Details(place: previewPlace)
        .modelContainer(for: Place.self)
}
