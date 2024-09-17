import SwiftUI
import Firebase
import FirebaseFirestore
import MapKit

class AdminTabViewModel: ObservableObject {
    @Published var driverLocations: [DriverLocation] = []
    @Published var currentOrder: OrderItem?
    @Published var mapAdminViewModel = MapAdminViewModel() // Модель представления карты
    @Published var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
    )
    @Published var isInitialRegionSet: Bool = false

    private let db = Firestore.firestore()

    // Метод получения местоположений водителей
    func fetchDriverLocations() {
        db.collection("DriverLocations").getDocuments { (snapshot, error) in
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
                if let order = self.currentOrder {
                    self.centerMapOnOrder(order)
                }
            }
        }
    }

    // Метод центрирования карты на заказе
    func centerMapOnOrder(_ order: OrderItem) {
        var minLat = min(order.senderLatitude, order.recipientLatitude)
        var maxLat = max(order.senderLatitude, order.recipientLatitude)
        var minLon = min(order.senderLongitude, order.recipientLongitude)
        var maxLon = max(order.senderLongitude, order.recipientLongitude)

        for driverLocation in driverLocations {
            minLat = min(minLat, driverLocation.latitude)
            maxLat = max(maxLat, driverLocation.latitude)
            minLon = min(minLon, driverLocation.longitude)
            maxLon = max(maxLon, driverLocation.longitude)
        }

        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let latDelta = (maxLat - minLat) * 1.2
        let lonDelta = (maxLon - minLon) * 1.2

        self.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }

    // Метод для увеличения масштаба карты
    func zoomIn() {
        let span = MKCoordinateSpan(latitudeDelta: region.span.latitudeDelta / 2, longitudeDelta: region.span.longitudeDelta / 2)
        region.span = span
    }

    // Метод для уменьшения масштаба карты
    func zoomOut() {
        let span = MKCoordinateSpan(latitudeDelta: region.span.latitudeDelta * 2, longitudeDelta: region.span.longitudeDelta * 2)
        region.span = span
    }
}
