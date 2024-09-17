import SwiftUI
import MapKit
import Firebase

class MapViewWithRouteViewModel: ObservableObject {
    @Published var region: MKCoordinateRegion
    @Published var route: MKRoute?
    
    private var order: OrderItem

    init(order: OrderItem) {
        self.order = order
        self.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: order.senderLatitude, longitude: order.senderLongitude),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }

    func calculateRoute(completion: @escaping (MKRoute?) -> Void) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: order.senderLatitude, longitude: order.senderLongitude)))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: order.recipientLatitude, longitude: order.recipientLongitude)))
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let route = response?.routes.first {
                DispatchQueue.main.async {
                    self.route = route
                    completion(route)
                }
            } else {
                completion(nil)
            }
        }
    }
}
