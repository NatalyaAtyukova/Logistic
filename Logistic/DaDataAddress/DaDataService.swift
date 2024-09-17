import Foundation
import SwiftUI
import CoreLocation

struct DaDataSuggestion: Codable, Hashable {
    let value: String
    let data: DaDataAddressData
    
    // Implementing Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
    
    static func == (lhs: DaDataSuggestion, rhs: DaDataSuggestion) -> Bool {
        return lhs.value == rhs.value && lhs.data == rhs.data
    }
}

struct DaDataAddressData: Codable, Hashable {
    let geo_lat: String?
    let geo_lon: String?
    var city_with_type: String? // Город с типом (например, "г. Москва")
    var street_with_type: String? // Улица с типом (например, "ул. Ленина")
}


class DaDataService {
    private let apiKey = "290df132e6eb7fe63974cce291b75b54d71d192f"

    func suggestAddress(query: String, completion: @escaping ([DaDataSuggestion]?) -> Void) {
        guard !query.isEmpty else {
            completion(nil)
            return
        }

        let url = URL(string: "https://suggestions.dadata.ru/suggestions/api/4_1/rs/suggest/address")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = ["query": query, "count": 10]
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching suggestions: \(error)")
                completion(nil)
                return
            }

            guard let data = data else {
                completion(nil)
                return
            }

            do {
                let result = try JSONDecoder().decode([String: [DaDataSuggestion]].self, from: data)
                completion(result["suggestions"])
            } catch {
                print("Error decoding suggestions: \(error)")
                completion(nil)
            }
        }
        task.resume()
    }
}
