import SwiftUI
import Firebase
import FirebaseFirestore
import MapKit
import CoreLocation

struct MapAdminView: UIViewRepresentable {
    @Binding var driverLocations: [DriverLocation]
    var order: OrderItem
    @Binding var region: MKCoordinateRegion
    @Binding var isInitialRegionSet: Bool

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator

        // Настройки карты
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.mapType = .standard  // .hybrid можно использовать для спутникового вида
        mapView.isRotateEnabled = false  // Запрещаем поворот карты
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)

        // Маркеры для водителей
        let driverAnnotations = driverLocations.map { location -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.title = "Водитель"
            annotation.subtitle = "Координаты: \(location.latitude), \(location.longitude)"
            annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            return annotation
        }

        // Маркер отправления
        let senderAnnotation = MKPointAnnotation()
        senderAnnotation.title = "Отправление"
        senderAnnotation.coordinate = CLLocationCoordinate2D(latitude: order.senderLatitude, longitude: order.senderLongitude)

        // Маркер получения
        let recipientAnnotation = MKPointAnnotation()
        recipientAnnotation.title = "Получение"
        recipientAnnotation.coordinate = CLLocationCoordinate2D(latitude: order.recipientLatitude, longitude: order.recipientLongitude)

        mapView.addAnnotations(driverAnnotations + [senderAnnotation, recipientAnnotation])

        // Показать все аннотации
        let annotations = driverAnnotations + [senderAnnotation, recipientAnnotation]
        mapView.showAnnotations(annotations, animated: true)

        // Построение маршрута
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: senderAnnotation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: recipientAnnotation.coordinate))
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error = error {
                print("Ошибка при расчете маршрута: \(error.localizedDescription)")
                return
            }

            guard let route = response?.routes.first else { return }
            mapView.addOverlay(route.polyline)

            DispatchQueue.main.async {
                if !isInitialRegionSet {
                    mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
                    isInitialRegionSet = true
                    region = mapView.region
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapAdminView

        init(_ parent: MapAdminView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.blue.withAlphaComponent(0.7)
                renderer.lineWidth = 5.0

                // Градиентный маршрут
                let gradientColors = [UIColor.blue.cgColor, UIColor.green.cgColor]
                let gradientLayer = CAGradientLayer()
                gradientLayer.colors = gradientColors
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        // Кастомизация аннотаций
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }

            let identifier = "CustomAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                
                if annotation.title == "Водитель" {
                    annotationView?.markerTintColor = .orange
                    annotationView?.glyphImage = UIImage(systemName: "car.fill")
                } else if annotation.title == "Отправление" {
                    annotationView?.markerTintColor = .blue
                    annotationView?.glyphImage = UIImage(systemName: "shippingbox.fill")
                } else if annotation.title == "Получение" {
                    annotationView?.markerTintColor = .green
                    annotationView?.glyphImage = UIImage(systemName: "house.fill")
                }
                
                // Добавляем кнопку для навигации
                let btn = UIButton(type: .detailDisclosure)
                annotationView?.rightCalloutAccessoryView = btn
            } else {
                annotationView?.annotation = annotation
            }
            return annotationView
        }
    }
}
