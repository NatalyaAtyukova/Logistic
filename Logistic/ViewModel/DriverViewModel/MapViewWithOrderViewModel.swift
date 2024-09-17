import SwiftUI
import MapKit
import Firebase
import CoreLocation

class MapViewWithOrderViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var region = MKCoordinateRegion()
    @Published var route: MKRoute?
    private var locationManager = CLLocationManager()
    private var order: OrderItem?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func updateRegion(for order: OrderItem) {
        self.order = order
        self.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: order.senderLatitude, longitude: order.senderLongitude),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        calculateRoute(for: order)
    }

    private func calculateRoute(for order: OrderItem) {
        guard let order = self.order else { return }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: order.senderLatitude, longitude: order.senderLongitude)))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: order.recipientLatitude, longitude: order.recipientLongitude)))
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let route = response?.routes.first {
                DispatchQueue.main.async {
                    self.route = route
                }
            }
        }
    }

    // Метод для обновления региона при изменении местоположения пользователя
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }
}
