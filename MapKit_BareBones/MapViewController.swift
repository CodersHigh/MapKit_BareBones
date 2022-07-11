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
            self.presentAlert(title: "오류 발생", message: "위치 서비스 제공이 불가합니다.")
        }
    }
    
    func checkAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted:
            self.presentAlert(title: "위치 서비스 제한", message: "자녀 보호로 인해 위치 서비스가 제한되었을 수 있습니다.")
            break
        case .denied:
            self.presentAlert(title: "위치 권한 거부", message: "설정으로 이동하여 앱에게 위치 접근 권한을 부여해야 사용 가능합니다.")
            break
        case .authorizedAlways, .authorizedWhenInUse:
            mapView.showsUserLocation = true
            if let coordinate = locationManager.location?.coordinate {
                present(at: coordinate)
                print("시뮬레이터에선 작동 안 함. 실제 폰에선 작동할까?")
            }
            locationManager.startUpdatingLocation()
            break
        @unknown default:
            break
        }
    }
    
    func present(at coordinate: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion.init(center: coordinate, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        mapView.setRegion(region, animated: true)
    }
}

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        present(at: coordinate)
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

extension MapViewController {
    
    func presentAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .cancel)
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }
    
}

