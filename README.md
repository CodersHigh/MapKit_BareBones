# MapKit_Barebones
<br/>

### 프로젝트 소개
- MapKit & CoreLocation의 기본적인 기능 구현을 익히는 데에 도움을 주는 Bare-bones 프로젝트입니다.
- MapKit & CoreLocation을 통해 간단한 지도 앱을 구현합니다.
   <details>
       <summary>다음과 같은 기능이 있습니다.</summary>
       
       - 위치 정보 접근 권한을 요청한 후, 사용자의 현위치와 주소를 알려주고       
       - 지도에서 선택했거나, 장소를 검색하여 얻은 위치에 주석을 표시하고 그 주소를 알려주며  
       - 현위치에서 선택 및 검색한 위치로 이동할 수 있는 경로를 표시함
       
   </details>
- SwiftUI에서는 지도에서 탭한 위치의 좌표를 불러오는 것이 불가능하여 **UIKit으로 구현**되었습니다.
- MapKit과 CoreLocation을 처음 활용해 보는 경우, 이 프로젝트의 코드를 살펴보면 도움이 됩니다.



https://user-images.githubusercontent.com/74223246/178630263-9fc4fcba-2a05-4e5d-8c86-39c6b9c0ff9b.mp4

<br/>

### MapKit & CoreLocation 이란?   

**MapKit**    
MapKit은 앱 내에서 **지도를 구현하고, 위치 세부 정보를 표시**할 수 있도록 해주는 프레임워크입니다.
<details>
    <summary>MapKit을 활용하면 이런 기능을 제공받을 수 있습니다.</summary>
    
    - 앱에 지도 표시 / 주석 및 오버레이를 활용하여 특정 위치 및 경로 표시
    - 텍스트 자동완성을 통한 쉬운 장소 검색
        
</details>

**CoreLocation**    
CoreLocation은 **기기의 지리적 위치 및 방향에 대한 정보**를 얻을 수 있는 프레임워크입니다.
CoreLocation의 위치 서비스를 사용하려면 위치 정보 접근 권한이 필요하므로, 사용자게에 접근 권한을 요청하는 메시지를 먼저 표시하게 됩니다.  
<details>
   <summary>CoreLocation을 활용하면 이런 기능을 제공받을 수 있습니다.</summary>
       
   - 사용자에게 위치 정보 접근 권한을 요청합니다. (위치 서비스를 사용하려면 권한이 필수!)
   - 사용자의 현재 위치 및 현위치에서의 크거나 작은 변화 추적
   - 사용자가 별개의 관심 영역에 들어오거나 나갈 때 위치 이벤트 생성
        
</details>
<br/>

### 핵심 코드
다음에 대한 코드가 첨부되어 있습니다. 필요한 코드를 참고해 보세요. 
- 얻은 좌표로 이동하여 주석 및 해당 위치의 주소 표시하기
- 경로 찾기 버튼 활성화 여부 결정하기 (새로운 좌표와 현위치 사이의 거리 판단하기)
- 위치 서비스 권한 부여 상태에 따른 처리 (권한 요청하기, 현위치 표시하기 등)
- 사용자의 현위치 추적 및 실시간 업데이트
- 지도에서 선택한 위치의 좌표 불러오기
- 장소 검색 자동완성 구현하기
- 현위치에서 선택 및 검색한 위치까지의 경로 안내하기 
<br/>

```Swift
// 얻은 좌표로 이동하여 주석 및 해당 위치의 주소 표시하기 

func present(at coordinate: CLLocationCoordinate2D) {
    // 얻은 좌표로 이동하기 & 해당 위치 주소 표시하기
        
    // 맵뷰에서 해당 좌표로 이동하기
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

// 기존의 annotation을 제거하고, 새로운 좌표에 annotation 추가
func updateAnnotation(at coordinate: CLLocationCoordinate2D) {
    self.mapView.removeAnnotations(self.mapView.annotations)
        
    let annotation = MKPointAnnotation()
    annotation.coordinate = coordinate
    self.mapView.addAnnotation(annotation)
}
```

<br/>
<br/>

```Swift
// 경로 찾기 버튼 활성화 여부 결정하기

// 새로운 좌표와 현위치의 사이 거리가 적당하다면(너무 짧지 않다면) 버튼 활성화
func updateFindPathButton(coordinate: CLLocationCoordinate2D) {
    if let currentCoordinate = locationManager.location?.coordinate{
        switch coordinate.isEnoughDistance(from: currentCoordinate) {
        case true:
            findPathButton.isEnabled = true
            selectedCoordinate = coordinate
        case false:
            findPathButton.isEnabled = false
        }
    }
}
```
```Swift
extension CLLocationCoordinate2D { 
    // isEnoughDistance 함수를 통해 두 좌표 간의 거리가 적당한지 - 너무 짧지 않은지 - 판단
    func isEnoughDistance(from: CLLocationCoordinate2D) -> Bool {
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: self.latitude, longitude: self.longitude)
        // 거리가 100미터를 넘으면 적당(true 반환), 100미터 미만이면 너무 짧음(false 반환)
        return from.distance(from: to) > 100 ? true : false
    }
}
```

<br/>
<br/>

```Swift
// CoreLocation 위치 서비스 가동 전

// 위치 서비스 제공 가능한지 확인
func checkLocationServices() {
    if CLLocationManager.locationServicesEnabled() {
        locationManager.delegate = self
        // desiredAccuracy : 위치 데이터의 정확성 / kCLLocationAccuracyBest : 최고의 정확도
        locationManager.desiredAccuracy = kCLLocationAccuracyBest 
        checkAuthorization()
    } else {
        // Alert 표시 - 오류 발생 : 위치 서비스 제공이 불가합니다. 
    }
}
    
// 위치 서비스 권한 부여 상태에 따른 처리
func checkAuthorization() {
    switch CLLocationManager.authorizationStatus() {
    case .notDetermined:
        // 권한 부여 여부가 결정되지 않았을 경우 : 권한 요청
        locationManager.requestWhenInUseAuthorization()
        break
    case .restricted:
        // 서비스가 제한되었을 경우
        // Alert 표시 - 위치 서비스 제한 : 자녀 보호로 인해 위치 서비스가 제한되었을 수 있습니다.
        break
    case .denied:
        // 권한이 거부되었을 경우
        // Alert 표시 - 위치 권한 거부 : 설정으로 이동하여 앱에게 위치 접근 권한을 부여해야 사용 가능합니다.
        break
    case .authorizedAlways, .authorizedWhenInUse:
        // 권한이 허가된 경우, 사용자의 현위치 표시
        mapView.showsUserLocation = true
        if let coordinate = locationManager.location?.coordinate {
            // present(at: )는 받은 좌표를 지도 중심에 표시되게 하고 주소를 업데이트함. 이후 등장할 예정. 
            present(at: coordinate)
        }
        locationManager.startUpdatingLocation()
        break
    @unknown default:
        break
    }
}
``` 
- CoreLocation에서 위치 서비스를 시작하기 전, 몇 가지 거쳐야 하는 단계가 있습니다.      
우선 **서비스가 제공 가능한지 확인**하고, 가능하다면 **위치 정보 접근 권한을 요청**합니다. 그리고 **접근 권한 부여 상태에 따라 처리**를 진행하는데요.    
아직 권한 부여 상태가 결정되지 않은 경우엔 권한을 요청하고, 권한이 허가된 경우엔 사용자의 현위치를 표시하며, 제한 및 거부 상태인 경우엔 Alert를 표시하도록 코드를 작성해야 합니다. 

<br/>
<br/>

```Swift
// 사용자의 현위치 추적 및 실시간 업데이트

func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }
    let coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    present(at: coordinate)
}
```

<br/>
<br/>

```Swift
// 지도에서 선택한 위치의 좌표 불러오기

// 뷰가 로드될 때 mapView에 Tap 제스처를 등록
override func viewDidLoad() { 
    // 탭했을 때 didTappedMapView를 수행하게 됨
    let tap = UITapGestureRecognizer(target: self, action: #selector(self.didTappedMapView(_:)))
    self.mapView.addGestureRecognizer(tap)
}

// mapView에서 탭한 좌표를 가지고 경로 찾기 버튼, 맵뷰, 주소 업데이트
@objc func didTappedMapView(_ sender: UITapGestureRecognizer) {
    let point: CGPoint = sender.location(in: self.mapView)
    let coordinate: CLLocationCoordinate2D = self.mapView.convert(point, toCoordinateFrom: self.mapView)
        
    // 탭이 끝났다면 경로 찾기 버튼, 주석, 맵뷰 및 주소 업데이트
    if sender.state == .ended {
        updateFindPathButton(coordinate: coordinate)
        updateAnnotation(at: coordinate)
        present(at: coordinate)
    }
}
```

<br/>
<br/>

```Swift
// 장소 검색 자동완성 구현하기

var searchCompleter = MKLocalSearchCompleter() // 검색을 도와줌
var searchResults = [MKLocalSearchCompletion]() // 검색 결과를 담음

extension SearchViewController: UISearchBarDelegate {
    // searBar의 텍스트가 바뀔 때마다 searchCompleter에게 queryFragment로 넘겨줌
    // queryFragment에 문자열을 할당하면, 해당 문자열을 기반으로 검색이 시작됨
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchCompleter.queryFragment = searchText
    }
}

extension SearchViewController: MKLocalSearchCompleterDelegate {
    // 자동완성 완료 시 결과를 받고 테이블뷰 리로드
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        self.searchTableView.reloadData()
    }
}

extension SearchViewController: UITableViewDataSource {
    // 테이블뷰 셀에 자동완성 검색 결과 표시
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell", for: indexPath)
        cell.textLabel?.text = searchResults[indexPath.row].title
        return cell
    }
}

// 선택한 검색 항목의 좌표를 노티피케이션으로 보내기

extension SearchViewController: UITableViewDelegate {
    // 셀을 눌렀을 때, 해당 항목의 좌표를 구해서 selectSearchItem 노티피케이션 전송
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedResult = searchResults[indexPath.row]
        let searchRequest = MKLocalSearch.Request(completion: selectedResult)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { (response, error) in
            guard error == nil else {
                print(error.debugDescription)
                return
            }
            guard let placeMark = response?.mapItems[0].placemark else { return }
            
            NotificationCenter.default.post(name: NSNotification.Name("selectSearchItem"), object: placeMark.coordinate)
            self.dismiss(animated: true)
        }
    }
}
```
```Swift
// 노티피케이션 받고 맵뷰 업데이트

override func viewDidLoad() {
    // Search 뷰컨에서 검색 항목을 선택했을 때 selectSearchItem 노티피케이션을 받음
    // 받았을 때 didReceiveSearchNotification을 실행하게 됨
    NotificationCenter.default.addObserver(self, selector: #selector(didReceiveSearchNotification), name: NSNotification.Name("selectSearchItem"), object: nil)
}

@objc func didReceiveSearchNotification(_ notification: Notification) {
    // selectSearchItem 노티피케이션을 받았을 때, 전달된 좌표로 경로 찾기 버튼, 주석, 맵뷰 및 주소 업데이트
    let searchCoordinate = notification.object as! CLLocationCoordinate2D
    updateAnnotation(at: searchCoordinate)
    updateFindPathButton(coordinate: searchCoordinate)
    present(at: searchCoordinate)
}
```
- `SearchViewController`에서 `searchBar`, `searchTableView`, `searchCompleter`의 delegate를 self로 지정하는 작업은 필수입니다!

<br/>
<br/>

```Swift
// 현위치에서 선택 및 검색한 위치까지의 경로 안내하기

@IBAction func findPathButtonTapped(_ sender: Any) {
    guard let currentCoordinate = locationManager.location?.coordinate else {
        self.presentAlert(title: "오류 발생", message: "현 위치 정보를 불러올 수 없습니다.")
        return
    }
    mapView.removeOverlays(mapView.overlays)
        
    // request 생성하기
    let startingLocation = MKPlacemark(coordinate: currentCoordinate)
    let destination = MKPlacemark(coordinate: selectedCoordinate!)
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
                // Alert 표시 - 오류 발생 : 경로 요청에 대한 응답을 받을 수 없습니다.
                return
            }
            if let route = response.routes.first {
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
            }
        }
    }
}
```
- `removeOverlays`를 통해 이전에 그려졌을 수 있는 경로를 모두 제거하고, `addOverlay`를 통해 새로 검색한 경로를 표시하게 됩니다.
- `setVisibleMapRect`를 통해 지도에서 현재 보이는 부분에서 가장자리 공간을 추가할 수 있습니다. `edgePadding`의 `UIEdgeInsets` 각 값을 변경하여 가장자리에 공간을 얼마나 추가할지 결정합니다.
