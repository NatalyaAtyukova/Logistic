import SwiftUI
import MapKit

struct MapViewWithRoute: UIViewRepresentable {
    var order: OrderItem
    @Binding var region: MKCoordinateRegion

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsTraffic = true
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)

        let senderAnnotation = MKPointAnnotation()
        senderAnnotation.title = "Откуда"
        senderAnnotation.coordinate = CLLocationCoordinate2D(latitude: order.senderLatitude, longitude: order.senderLongitude)

        let recipientAnnotation = MKPointAnnotation()
        recipientAnnotation.title = "Куда"
        recipientAnnotation.coordinate = CLLocationCoordinate2D(latitude: order.recipientLatitude, longitude: order.recipientLongitude)

        mapView.addAnnotations([senderAnnotation, recipientAnnotation])

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
