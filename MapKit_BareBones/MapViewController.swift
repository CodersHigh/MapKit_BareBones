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
    @IBOutlet weak var displayAddressLabel: UILabel!
    
    // 내 위치 버튼 눌렀을 때,
    @IBAction func findMyLocationButtonTapped(_ sender: Any) {
        self.mapView.showsUserLocation = true
        self.mapView.setUserTrackingMode(.follow, animated: true)
        if let coordinate = locationManager.location?.coordinate {
            present(at: coordinate)
        }
    }
    
    let locationManager = CLLocationManager()
    let regionInMeters: Double = 1000
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkLocationServices()
        displayAddressView.layer.cornerRadius = 12
        
        // mapView에서 탭 동작을 인식하면 didTappedMapView를 실행
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.didTappedMapView(_:)))
        self.mapView.addGestureRecognizer(tap)
    }
    
    // mapView에서 탭한 좌표를 가지고 맵뷰 및 주소 업데이트
    @objc func didTappedMapView(_ sender: UITapGestureRecognizer) {
        let point: CGPoint = sender.location(in: self.mapView)
        let coordinate: CLLocationCoordinate2D = self.mapView.convert(point, toCoordinateFrom: self.mapView)
        self.mapView.removeAnnotations(self.mapView.annotations)

        if sender.state == .ended {
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            self.mapView.addAnnotation(annotation)
            present(at: coordinate)
        }
    }
    
    // 위치 서비스 제공 가능한지 확인
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            checkAuthorization()
        } else {
            self.presentAlert(title: "오류 발생", message: "위치 서비스 제공이 불가합니다.")
        }
    }
    
    // 위치 서비스 권한 부여 상태에 따른 처리
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
            }
            locationManager.startUpdatingLocation()
            break
        @unknown default:
            break
        }
    }
    
    // 받은 좌표를 맵뷰 및 주소 업데이트
    func present(at coordinate: CLLocationCoordinate2D) {
        
        // 맵뷰에서 해당 좌표 표시하기
        let region = MKCoordinateRegion.init(center: coordinate, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        mapView.setRegion(region, animated: true)
        
        // 해당 좌표의 주소 표시하기
        let geocoder: CLGeocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let locale = Locale(identifier: "Ko-kr")
        
        geocoder.reverseGeocodeLocation(location, preferredLocale: locale) { (placemarks, error) in
            if let address: [CLPlacemark] = placemarks {
                if let country = address.last?.country, let administrativeArea = address.last?.administrativeArea, let locality = address.last?.locality, let name = address.last?.name {
                    let displayAddress = "\(country) \(administrativeArea) \(locality) \(name)"
                    self.displayAddressLabel.text = displayAddress
                }
            }
        }
    }
    
}

extension MapViewController: CLLocationManagerDelegate {
    
    // 위치가 바뀔 때마다 맵뷰와 주소도 업데이트
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        present(at: coordinate) 
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }

}

extension MapViewController {
    
    func presentAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .cancel)
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }
    
}

