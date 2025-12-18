//
//  Place.swift
//  Mock_Test_240144419
//
//  Created by user on 17/12/2025.
//

import Foundation
import SwiftData

@Model
class Place{
    @Attribute(.unique) var id: UUID = UUID()
    var name : String
    var category : String
    var place_description : String
    var lat :Double
    var lng : Double
    init(id: UUID, name: String, category: String, place_description: String, lat: Double, lng: Double) {
        self.id = id
        self.name = name
        self.category = category
        self.place_description = place_description
        self.lat = lat
        self.lng = lng
    }
}
