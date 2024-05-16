// YelpService.swift

import Foundation
import CoreLocation

struct YelpBusiness: Decodable {
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

class YelpService {
    let apiKey = "CSz988mO5kfKLL2jh2-mdfMmyWYQresMsucDoL4WfR3hUDUNqsMJ2WgwY4EgMPnQEGsLr2qJkin-AAtK2cSBF7QGuNZ2MKAPKN-Z3_1sQgj7-1F6SljgwzTzvC1AZnYx"
    
    func searchBusinesses(query: String, location: CLLocation, completion: @escaping ([YelpBusiness]) -> Void) {
        guard let url = URL(string: "https://api.yelp.com/v3/businesses/search?term=\(query)&latitude=\(location.coordinate.latitude)&longitude=\(location.coordinate.longitude)") else {
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Network error: \(String(describing: error))")
                return
            }

            do {
                let yelpResponse = try JSONDecoder().decode(YelpResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(yelpResponse.businesses)
                }
            } catch {
                print("JSON error: \(error)")
            }
        }
        task.resume()
    }
}
