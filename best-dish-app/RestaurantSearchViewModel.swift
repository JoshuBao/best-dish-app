//
//  RestaurantSearchViewModel.swift
//  best-dish-app
//
//  Created by Joshua Cheng on 5/16/24.


import SwiftUI
import Combine
import CoreLocation

class RestaurantSearchViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var dishName: String = ""
    @Published var query: String = ""
    @Published var businesses: [YelpBusiness] = []
    @Published var selectedBusiness: YelpBusiness?
    @Published var location: CLLocation?
    var yelpService = YelpService()
    private var locationManager: CLLocationManager?
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()

        // Initialize CLLocationManager
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()
        $query
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] query in
                self?.searchBusinesses(query: query)
            }
            .store(in: &cancellables)
    }

    func startUpdatingLocation() {
        locationManager?.startUpdatingLocation()
    }

    func searchBusinesses(query: String) {
        guard let location = location, !query.isEmpty else { return }
        yelpService.searchBusinesses(query: query, location: location) { [weak self] businesses in
            self?.businesses = businesses
        }
    }

    // CLLocationManagerDelegate method to update location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.location = location
            locationManager?.stopUpdatingLocation() // Stop updating to save battery
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error.localizedDescription)")
    }
}
