//
//  MapViewController.swift
//  MapKit_BareBones
//
//  Created by 이로운 on 2022/07/11.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    
    @IBOutlet weak var locationSearchBar: UISearchBar!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var displayAddressView: UIView!
    
    @IBAction func findMyLocationButtonTapped(_ sender: Any) {
        self.mapView.showsUserLocation = true
        self.mapView.setUserTrackingMode(.follow, animated: true)
    }
    
    let locationManager = CLLocationManager()
    let regionInMeters: Double = 10000
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkLocationServices()
        displayAddressView.layer.cornerRadius = 12
    }
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            checkAuthorization()
        } else {
            
        }
    }
    
    func checkAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted:
            print("Your location is restricted likely due to parental controls.")
            break
        case .denied:
            print("Your have denied this app location permisson. Go into settings to change it.")
            break
        case .authorizedAlways, .authorizedWhenInUse:
            mapView.showsUserLocation = true
            //mapView.setUserTrackingMode(.follow, animated: true)
            locationManager.startUpdatingLocation()
            break
        @unknown default:
            break
        }
    }
    
    func move(at coordinate: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion.init(center: coordinate, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        mapView.setRegion(region, animated: true)
    }
}

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        let coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        move(at: coordinate)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkAuthorization()
    }
    
    /*
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
     */
    
    /*
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
    }
     */
}

