import SwiftUI
import Firebase
import MapKit
import CoreLocation
import FirebaseFirestore


struct MapViewWithRoute: UIViewRepresentable {
    var order: OrderItem
    @Binding var region: MKCoordinateRegion

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        
        // Включаем отображение пробок
        mapView.showsTraffic = true
        
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Удалить все предыдущие аннотации и оверлеи
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)

        // Создать аннотации для отправителя и получателя
        let senderAnnotation = MKPointAnnotation()
        senderAnnotation.title = "Откуда"
        senderAnnotation.coordinate = CLLocationCoordinate2D(latitude: order.senderLatitude, longitude: order.senderLongitude)

        let recipientAnnotation = MKPointAnnotation()
        recipientAnnotation.title = "Куда"
        recipientAnnotation.coordinate = CLLocationCoordinate2D(latitude: order.recipientLatitude, longitude: order.recipientLongitude)

        // Добавить аннотации на карту
        mapView.addAnnotations([senderAnnotation, recipientAnnotation])

        // Прорисовать маршрут между точками
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: senderAnnotation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: recipientAnnotation.coordinate))
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let route = response?.routes.first {
                mapView.addOverlay(route.polyline)
                mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 100, left: 50, bottom: 50, right: 50), animated: true)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewWithRoute

        init(_ parent: MapViewWithRoute) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}


//запись в бд геолокации
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var lastKnownLocation: CLLocation?
    @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocationPermission() {
        manager.requestAlwaysAuthorization()
    }

    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastKnownLocation = location
        region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        saveLocationToFirestore(location: location)
    }

    func saveLocationToFirestore(location: CLLocation) {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("DriverLocations").document(userID).setData([
            "driverID": userID,
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "timestamp": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Ошибка при сохранении геопозиции: \(error.localizedDescription)")
            } else {
                print("Геопозиция успешно сохранена")
            }
        }
    }
}
