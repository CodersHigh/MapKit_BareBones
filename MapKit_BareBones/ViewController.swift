//
//  ViewController.swift
//  MapKit_BareBones
//
//  Created by 이로운 on 2022/07/11.
//

import UIKit

class MapViewController: UIViewController {
    
    @IBOutlet weak var searchLocationBar: UISearchBar!
    @IBOutlet weak var findMyLocationButton: UIButton!
    @IBOutlet weak var displayAddressView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUI()
    }
    
    func setUI() {
        displayAddressView.layer.cornerRadius = 12
    }

}

