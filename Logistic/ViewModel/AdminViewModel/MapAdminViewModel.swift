import SwiftUI
import MapKit
import Firebase
import FirebaseFirestore

class MapAdminViewModel: ObservableObject {
    @Published var driverLocations: [DriverLocation] = []
    @Published var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
    )
    @Published var isInitialRegionSet = false
    
    private let db = Firestore.firestore()

    func fetchDriverLocations() {
        db.collection("DriverLocations").getDocuments { snapshot, error in
            if let error = error {
                print("Ошибка получения местоположений водителей: \(error.localizedDescription)")
                return
            }
            
            var fetchedLocations: [DriverLocation] = []
            snapshot?.documents.forEach { document in
                let data = document.data()
                
                // Извлекаем данные из документа
                if let driverID = data["driverID"] as? String,
                   let latitude = data["latitude"] as? Double,
                   let longitude = data["longitude"] as? Double,
                   let timestamp = data["timestamp"] as? Timestamp { // Используем Timestamp
                    
                    // Создаем объект DriverLocation
                    let location = DriverLocation(
                        id: document.documentID,
                        driverID: driverID,
                        latitude: latitude,
                        longitude: longitude,
                        timestamp: timestamp // Передаем Timestamp напрямую
                    )
                    
                    fetchedLocations.append(location)
                }
            }
            
            DispatchQueue.main.async {
                self.driverLocations = fetchedLocations
            }
        }
    }
    
    // Реализация функции построения маршрута
    func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, completion: @escaping (MKPolyline?) -> Void) {
        let sourcePlacemark = MKPlacemark(coordinate: source)
        let destinationPlacemark = MKPlacemark(coordinate: destination)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = MKMapItem(placemark: destinationPlacemark)
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error = error {
                print("Ошибка при расчете маршрута: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let route = response?.routes.first {
                completion(route.polyline)
            } else {
                completion(nil)
            }
        }
    }
    
    // Реализация функции обновления области карты
    func updateRegion(for mapView: MKMapView, with polyline: MKPolyline) {
        let rect = polyline.boundingMapRect
        mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
        isInitialRegionSet = true
    }
}
