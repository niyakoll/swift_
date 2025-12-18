//
//  Details.swift
//  Mock_Test_240144419
//

import SwiftUI
import MapKit
import CoreData

struct Details: View {
    let place: Place
    
    @State private var region: MKCoordinateRegion
    
    init(place: Place) {
        self.place = place
        let center = CLLocationCoordinate2D(latitude: place.lat, longitude: place.lng)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        _region = State(initialValue: MKCoordinateRegion(center: center, span: span))
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Name: \(place.name ?? "")")
            Text("Description: \(place.place_description ?? "")")
            Text("Latitude: \(place.lat)")
            Text("Longitude: \(place.lng)")
            
            // Old iOS 15 Map
            Map(coordinateRegion: $region,
                annotationItems: [place]) { place in
                MapMarker(
                    coordinate: CLLocationCoordinate2D(latitude: place.lat, longitude: place.lng),
                    tint: .red
                )
            }
            .frame(height: 300)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Place Details")
    }
}


