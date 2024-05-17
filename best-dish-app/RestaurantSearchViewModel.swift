import SwiftUI
import Combine
import CoreLocation

class RestaurantSearchViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var dishName: String = ""
    @Published var query: String = ""
    @Published var allBusinesses: [YelpBusiness] = []
    @Published var filteredBusinesses: [YelpBusiness] = []
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
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] query in
                self?.filterBusinesses(query: query)
            }
            .store(in: &cancellables)
    }

    func startUpdatingLocation() {
        locationManager?.startUpdatingLocation()
    }

    func fetchNearbyBusinesses() {
        guard let location = location else { return }
        yelpService.fetchNearbyBusinesses(location: location) { [weak self] businesses in
            DispatchQueue.main.async {
                self?.allBusinesses = businesses
                self?.filterBusinesses(query: self?.query ?? "")
            }
        }
    }

    func filterBusinesses(query: String) {
        if query.isEmpty {
            filteredBusinesses = allBusinesses
        } else {
            filteredBusinesses = allBusinesses.filter { $0.name.lowercased().contains(query.lowercased()) }
        }
    }

    // CLLocationManagerDelegate method to update location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.location = location
            fetchNearbyBusinesses()
            locationManager?.stopUpdatingLocation() // Stop updating to save battery
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            print("Location access denied.")
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        @unknown default:
            fatalError()
        }
    }
}
