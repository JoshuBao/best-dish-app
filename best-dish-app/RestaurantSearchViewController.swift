//
//  RestaurantSearchViewController.swift
//  best-dish-app
//
//  Created by Joshua Cheng on 5/16/24.
//

// RestaurantSearchViewController.swift


import UIKit
import CoreLocation

class RestaurantSearchViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate {
    var textField: UITextField!
    var tableView: UITableView!
    var allBusinesses: [YelpBusiness] = []
    var filteredBusinesses: [YelpBusiness] = []
    var yelpService = YelpService()
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupLocationManager()
    }

    func setupViews() {
        textField = UITextField(frame: CGRect(x: 20, y: 100, width: view.frame.width - 40, height: 40))
        textField.borderStyle = .roundedRect
        textField.placeholder = "Enter restaurant name"
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        view.addSubview(textField)
        
        tableView = UITableView(frame: CGRect(x: 20, y: 150, width: view.frame.width - 40, height: 300))
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
    }

    func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            currentLocation = location
            locationManager.stopUpdatingLocation() // Stop updating to save battery
            fetchNearbyBusinesses()
        }
    }

    func fetchNearbyBusinesses() {
        guard let location = currentLocation else { return }
        yelpService.fetchNearbyBusinesses(location: location) { [weak self] businesses in
            self?.allBusinesses = businesses
            self?.filterBusinesses(query: self?.textField.text ?? "")
        }
    }

    @objc func textFieldDidChange() {
        guard let query = textField.text else {
            filteredBusinesses.removeAll()
            tableView.reloadData()
            return
        }

        filterBusinesses(query: query)
    }

    func filterBusinesses(query: String) {
        if query.isEmpty {
            filteredBusinesses = allBusinesses
        } else {
            filteredBusinesses = allBusinesses.filter { $0.name.lowercased().contains(query.lowercased()) }
        }
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredBusinesses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let business = filteredBusinesses[indexPath.row]
        cell.textLabel?.text = business.name
        cell.detailTextLabel?.text = business.location.address1 ?? business.location.city
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let business = filteredBusinesses[indexPath.row]
        textField.text = business.name
        tableView.isHidden = true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        tableView.isHidden = false
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        filteredBusinesses.removeAll()
        tableView.reloadData()
        return true
    }
}
