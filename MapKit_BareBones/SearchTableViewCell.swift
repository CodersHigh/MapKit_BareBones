//
//  SearchTableViewCell.swift
//  MapKit_BareBones
//
//  Created by 이로운 on 2022/07/12.
//

import UIKit

class SearchTableViewCell: UITableViewCell {
    static let identifier = "SearchCell"
    
    let countryLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .lightGray
        return label
    }()

}
