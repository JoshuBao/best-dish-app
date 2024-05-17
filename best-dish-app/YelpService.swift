import Foundation
import CoreLocation

struct YelpBusiness: Decodable {
    let id: String
    let name: String
    let location: YelpLocation
}

struct YelpLocation: Decodable {
    let address1: String?
    let city: String
}

struct YelpResponse: Decodable {
    let businesses: [YelpBusiness]
}

struct CachedResponse {
    let businesses: [YelpBusiness]
    let timestamp: Date
    let location: CLLocation
}

class YelpService {
    let apiKey = "CSz988mO5kfKLL2jh2-mdfMmyWYQresMsucDoL4WfR3hUDUNqsMJ2WgwY4EgMPnQEGsLr2qJkin-AAtK2cSBF7QGuNZ2MKAPKN-Z3_1sQgj7-1F6SljgwzTzvC1AZnYx"
    private var cache: [String: CachedResponse] = [:]
    private let cacheDuration: TimeInterval = 24 * 60 * 60 // Cache duration in seconds (24 hours)
    private let maxDistance: Double = 5 * 1609.34 // Maximum distance in meters (5 miles)
    
    func fetchNearbyBusinesses(location: CLLocation, completion: @escaping ([YelpBusiness]) -> Void) {
        let cacheKey = "\(location.coordinate.latitude)-\(location.coordinate.longitude)"
        
        if let cachedResponse = cache[cacheKey] {
            let distance = cachedResponse.location.distance(from: location)
            let timeInterval = Date().timeIntervalSince(cachedResponse.timestamp)
            
            print("Cache check for location: \(location)")
            print("Distance: \(distance) meters")
            print("Time interval: \(timeInterval) seconds")
            
            if timeInterval < cacheDuration && distance <= maxDistance {
                print("Using cached data for location: \(location)")
                completion(cachedResponse.businesses)
                return
            } else {
                print("Cache expired for location: \(location)")
            }
        }
        
        print("Making API call for location: \(location)")
        
        let limit = 50
        let totalFetchCount = 200
        var fetchedBusinesses: [YelpBusiness] = []
        
        let dispatchGroup = DispatchGroup()
        
        for offset in stride(from: 0, to: totalFetchCount, by: limit) {
            dispatchGroup.enter()
            
            let urlString = "https://api.yelp.com/v3/businesses/search?latitude=\(location.coordinate.latitude)&longitude=\(location.coordinate.longitude)&limit=\(limit)&offset=\(offset)&sort_by=distance"
            guard let url = URL(string: urlString) else {
                dispatchGroup.leave()
                return
            }
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                defer { dispatchGroup.leave() }
                
                guard let data = data, error == nil else {
                    print("Network error: \(String(describing: error))")
                    return
                }
                
                // Log the raw JSON response
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw JSON response: \(jsonString)")
                }
                
                do {
                    let yelpResponse = try JSONDecoder().decode(YelpResponse.self, from: data)
                    fetchedBusinesses.append(contentsOf: yelpResponse.businesses)
                } catch {
                    print("JSON error: \(error)")
                }
            }
            task.resume()
        }
        
        dispatchGroup.notify(queue: .main) {
            let cachedResponse = CachedResponse(businesses: fetchedBusinesses, timestamp: Date(), location: location)
            self.cache[cacheKey] = cachedResponse
            completion(fetchedBusinesses)
        }
    }
}
