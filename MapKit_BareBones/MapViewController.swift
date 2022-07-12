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
    @IBOutlet weak var findPathButton: UIButton!
    
    // 내 위치 버튼 눌렀을 때, 내 위치로 돌아가기
    @IBAction func findMyLocationButtonTapped(_ sender: Any) {
        self.mapView.showsUserLocation = true
        self.mapView.setUserTrackingMode(.follow, animated: true)
        if let coordinate = locationManager.location?.coordinate {
            present(at: coordinate)
        }
        self.findPathButton.isEnabled = false
    }
    
    // 경로 찾기 버튼을 눌렀을 때, 경로 안내하기
    @IBAction func findPathButtonTapped(_ sender: Any) {
        guard let currentCoordinate = locationManager.location?.coordinate else {
            
            return
        }
        mapView.removeOverlays(mapView.overlays)
        
        // request 생성하기
        let startingLocation = MKPlacemark(coordinate: currentCoordinate)
        let destination = MKPlacemark(coordinate: tappedCoordinate!)
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        request.requestsAlternateRoutes = false
        
        // 요청된 경로 정보 계산하고 나타내기
        let directions = MKDirections(request: request)
        directions.calculate { [unowned self] (response, error) in
            // 에러 핸들링하기
            guard let response = response else { return } // Show response not available in an alert
            if let route = response.routes.first {
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    let locationManager = CLLocationManager()
    let regionInMeters: Double = 1000
    var tappedCoordinate: CLLocationCoordinate2D?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkLocationServices()
        displayAddressView.layer.cornerRadius = 12
        
        self.findPathButton.isEnabled = false
        
        // mapView에서 탭 동작을 인식하면 didTappedMapView를 실행
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.didTappedMapView(_:)))
        self.mapView.addGestureRecognizer(tap)
    }
    
    // mapView에서 탭한 좌표를 가지고 맵뷰 및 주소 업데이트
    @objc func didTappedMapView(_ sender: UITapGestureRecognizer) {
        let point: CGPoint = sender.location(in: self.mapView)
        let coordinate: CLLocationCoordinate2D = self.mapView.convert(point, toCoordinateFrom: self.mapView)
        self.tappedCoordinate = coordinate
        self.mapView.removeAnnotations(self.mapView.annotations)
        
        // 탭한 좌표와 현위치의 좌표 사이 거리가 적당하다면 - 너무 짧지 않다면 - 경로 찾기 버튼 활성화
        if let currentCoordinate = locationManager.location?.coordinate{
            switch coordinate.isEnoughDistance(from: currentCoordinate) {
            case true:
                findPathButton.isEnabled = true
            case false:
                findPathButton.isEnabled = false
            }
        }

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

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let render = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        render.strokeColor = .blue
        
        return render
    }
}

// 다른 파일로 분리할 것들

extension UIViewController {
    
    func presentAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .cancel)
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }
    
}

extension CLLocationCoordinate2D {
    
    // 두 좌표 간의 거리가 적당한지 - 너무 짧지 않은지 - 판단
    func isEnoughDistance(from: CLLocationCoordinate2D) -> Bool {
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: self.latitude, longitude: self.longitude)
        // 거리가 100미터를 넘으면 적당(true), 100미터 미만이면 너무 짧음(false)
        return from.distance(from: to) > 100 ? true : false
    }
    
}
