//
//  SearchViewController.swift
//  MapKit_BareBones
//
//  Created by 이로운 on 2022/07/12.
//

import UIKit
import MapKit

class SearchViewController: UIViewController {
    
    // MARK: - IBOutlet & IBAction
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchTableView: UITableView!
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    // MARK: - Properties
    
    var searchCompleter = MKLocalSearchCompleter() // 검색을 도와줌
    var searchResults = [MKLocalSearchCompletion]() // 검색 결과를 담음

    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.becomeFirstResponder()
        
        searchBar.delegate = self
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
        searchTableView.delegate = self
        searchTableView.dataSource = self
        searchTableView.separatorStyle = .none
    }
}

// MARK: - UITableViewDelegate

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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.searchBar.resignFirstResponder()
    }
    
}

 // MARK: - UITableViewDataSource

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

// MARK: - UISearchBarDelegate

extension SearchViewController: UISearchBarDelegate {
    
    // searBar의 텍스트가 바뀔 때마다 searchCompleter에게 queryFragment로 넘겨줌
    // queryFragment에 문자열을 할당하면, 해당 문자열을 기반으로 검색이 시작됨
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchCompleter.queryFragment = searchText
    }
    
}

// MARK: - MKLocalSearchCompleterDelegate

extension SearchViewController: MKLocalSearchCompleterDelegate {
    
    // 자동완성 완료 시 결과를 받고 테이블뷰 리로드
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        self.searchTableView.reloadData()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
}
