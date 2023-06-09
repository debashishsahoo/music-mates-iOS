//
//  MapViewController.swift
//  MusicMates
//
//  Created by Debashish Sahoo on 29/5/2023.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    var annotation: MKAnnotation!
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the preferred configuration of the map to be hybrid
        mapView.preferredConfiguration = MKHybridMapConfiguration()
        
        // Add the Annotation object passed to this controller by the relevant segue when the user selects another user in the Discover Friends page
        mapView.addAnnotation(annotation)
        mapView.selectAnnotation(annotation, animated: true)
        
        // Zooms in and centers the map at the location of the annotation
        let zoomRegion = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(zoomRegion, animated: true)

    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
