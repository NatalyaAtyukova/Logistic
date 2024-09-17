import SwiftUI
import Firebase
import FirebaseFirestore
import CoreLocation

class DriverTabViewModel: ObservableObject {
    @Published var orders: [OrderItem] = []
    @Published var driverLocations: [DriverLocation] = []
    
    private let db = Firestore.firestore()

    func fetchDriverLocations() {
        db.collection("DriverLocations").addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Error fetching driver locations: \(error.localizedDescription)")
                return
            }

            var fetchedDriverLocations: [DriverLocation] = []

            for document in snapshot!.documents {
                let data = document.data()
                if let driverID = data["driverID"] as? String,
                   let latitude = data["latitude"] as? Double,
                   let longitude = data["longitude"] as? Double,
                   let timestamp = data["timestamp"] as? Timestamp {

                    let location = DriverLocation(id: document.documentID, driverID: driverID, latitude: latitude, longitude: longitude, timestamp: timestamp)
                    fetchedDriverLocations.append(location)
                }
            }

            DispatchQueue.main.async {
                self.driverLocations = fetchedDriverLocations
            }
        }
    }
    
    func fetchOrders(for userID: String) {
        db.collection("Orders")
            .whereField("driverID", isEqualTo: userID)
            .addSnapshotListener { (snapshot, error) in
                if let error = error {
                    print("Error fetching orders: \(error.localizedDescription)")
                    return
                }

                var fetchedOrders: [OrderItem] = []

                for document in snapshot!.documents {
                    do {
                        let order = try document.data(as: OrderItem.self)
                        fetchedOrders.append(order)
                    } catch {
                        print("Error decoding order: \(error)")
                    }
                }

                DispatchQueue.main.async {
                    self.orders = fetchedOrders
                }
            }
    }
}
