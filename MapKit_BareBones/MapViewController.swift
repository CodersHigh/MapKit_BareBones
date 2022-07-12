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
    
    // MARK: - IBOutlet & IBAction
    
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
            self.presentAlert(title: "오류 발생", message: "현 위치 정보를 불러올 수 없습니다.")
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
            if let error = error {
                print(error.localizedDescription)
            } else {
                guard let response = response else {
                    self.presentAlert(title: "오류 발생", message: "경로 요청에 대한 응답을 받을 수 없습니다.")
                    return
                }
                if let route = response.routes.first {
                    self.mapView.addOverlay(route.polyline)
                    self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                }
            }
        }
    }
    
    // MARK: - Properties
    
    let locationManager = CLLocationManager()
    let regionInMeters: Double = 1000 // latitudinalMeters 및 longitudinalMeters의 기본값
    var tappedCoordinate: CLLocationCoordinate2D? // MapView에서 탭한 위치의 좌표를 담음
    var searchCompleter = MKLocalSearchCompleter() // 검색을 도와줌
    var searchResults = [MKLocalSearchCompletion]() // 검색 결과를 담음
    
    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkLocationServices()
        displayAddressView.layer.cornerRadius = 12
        
        // searchCompleter 세팅
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
        
        self.findPathButton.isEnabled = false
        
        // mapView에서 탭 동작을 인식하면 didTappedMapView를 실행
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.didTappedMapView(_:)))
        self.mapView.addGestureRecognizer(tap)
    }
    
    // MARK: - functions
    
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
        
        // 탭이 끝났다면 annotation 표시 & 맵뷰 및 주소 업데이트
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

// MARK: - UISearchBarDelegate

extension MapViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchCompleter.queryFragment = searchText
    }
    
}

// MARK: - MKLocalSearchCompleterDelegate

extension MapViewController: MKLocalSearchCompleterDelegate {
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        // tableView 리로드
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
}

// MARK: - UITableViewDataSource

extension MapViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell", for: indexPath) as? SearchTableViewCell else { return UITableViewCell() }
        return cell
    }
    
}

// MARK: - CLLocationManagerDelegate

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

// MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let render = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        render.strokeColor = .blue
        
        return render
    }
}
