//
//  LocationAnnotation.swift
//  MusicMates
//
//  Created by Debashish Sahoo on 31/5/2023.
//

import UIKit
import MapKit

class LocationAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?

    init(title: String, lat: Double, long: Double) {
        self.title = title
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
    }
}
