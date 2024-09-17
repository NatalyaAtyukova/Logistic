import SwiftUI
import MapKit
import CoreLocation

struct MapAdminView: UIViewRepresentable {
    @ObservedObject var viewModel: MapAdminViewModel // Передаем ViewModel вместо отдельных состояний
    var order: OrderItem

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.mapType = .standard
        mapView.isRotateEnabled = false
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)

        // Аннотации водителей
        let driverAnnotations = viewModel.driverLocations.map { location -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.title = "Водитель"
            annotation.subtitle = "Координаты: \(location.latitude), \(location.longitude)"
            annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            return annotation
        }

        // Аннотации отправления и получения
        let senderAnnotation = MKPointAnnotation()
        senderAnnotation.title = "Отправление"
        senderAnnotation.coordinate = CLLocationCoordinate2D(latitude: order.senderLatitude, longitude: order.senderLongitude)

        let recipientAnnotation = MKPointAnnotation()
        recipientAnnotation.title = "Получение"
        recipientAnnotation.coordinate = CLLocationCoordinate2D(latitude: order.recipientLatitude, longitude: order.recipientLongitude)

        mapView.addAnnotations(driverAnnotations + [senderAnnotation, recipientAnnotation])
        mapView.showAnnotations(driverAnnotations + [senderAnnotation, recipientAnnotation], animated: true)

        // Построение маршрута
        viewModel.calculateRoute(from: senderAnnotation.coordinate, to: recipientAnnotation.coordinate) { polyline in
            if let polyline = polyline {
                mapView.addOverlay(polyline)
                if !viewModel.isInitialRegionSet {
                    viewModel.updateRegion(for: mapView, with: polyline)
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
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

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
                
                let btn = UIButton(type: .detailDisclosure)
                annotationView?.rightCalloutAccessoryView = btn
            } else {
                annotationView?.annotation = annotation
            }
            return annotationView
        }
    }
}
