//
//  CoordinateExtension.swift
//  MapKit_BareBones
//
//  Created by 이로운 on 2022/07/12.
//

import UIKit
import CoreLocation

extension CLLocationCoordinate2D {
    
    // 두 좌표 간의 거리가 적당한지 - 너무 짧지 않은지 - 판단
    func isEnoughDistance(from: CLLocationCoordinate2D) -> Bool {
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: self.latitude, longitude: self.longitude)
        // 거리가 100미터를 넘으면 적당(true), 100미터 미만이면 너무 짧음(false)
        return from.distance(from: to) > 100 ? true : false
    }
    
}
