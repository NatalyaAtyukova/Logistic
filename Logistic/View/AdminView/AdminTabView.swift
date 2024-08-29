import SwiftUI
import Firebase
import FirebaseFirestore
import MapKit
import CoreLocation

struct AdminTabView: View {
    @StateObject private var alertManager = AlertManager()
    @StateObject private var locationManager = LocationManager()
    @State private var driverLocations: [DriverLocation] = []
    @State private var currentOrder: OrderItem?
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
    )
    @State private var isInitialRegionSet: Bool = false
    
    let userID: String
    
    var body: some View {
        TabView {
            NavigationView {
                OrdersListView(selectedOrder: $currentOrder, alertManager: alertManager)
                    .navigationTitle("Список заказов")
                    .navigationBarTitleDisplayMode(.inline)
                    .background(Color(.systemGroupedBackground)) // Фон для списка
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("Список заказов")
            }

            AddOrderView(alertManager: alertManager)
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Добавить заказ")
                }

            if let order = currentOrder {
                VStack(spacing: 0) {
                    ZStack(alignment: .topTrailing) {
                        MapAdminView(driverLocations: $driverLocations, order: order, region: $region, isInitialRegionSet: $isInitialRegionSet)
                            .edgesIgnoringSafeArea(.all) // Позволяет карте занимать весь экран
                            .shadow(radius: 10) // Добавляем тень
                        
                        VStack {
                            ZoomControlsView(zoomIn: zoomIn, zoomOut: zoomOut)
                                .padding(.top, 50)
                                .padding(.trailing, 10)
                        }
                    }

                    // Информация о заказе с улучшенным стилем
                    Text("Заказ №\(order.id)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top)
                    
                    Text("\(order.senderAddress) -> \(order.recipientAddress)")
                        .font(.body)
                        .foregroundColor(.gray)
                        .padding([.leading, .trailing, .bottom])
                }
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Карта")
                }
                .onAppear {
                    centerMapOnOrder(order)
                }
            } else {
                VStack {
                    Spacer()
                    Text("Выберите заказ для отображения на карте")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .tabItem {
                    Image(systemName: "map")
                    Text("Карта")
                }
            }

            ChatAdminView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Чат")
                }

            UserProfileView(userID: userID, role: "admin")
                .tabItem {
                    Label("Профиль", systemImage: "person.crop.circle.fill")
                }
        }
        .accentColor(.blue) // Основной цвет иконок
        .navigationBarTitle("Панель организации")
        .onAppear {
            locationManager.requestLocationPermission()
            locationManager.startUpdatingLocation()
            fetchDriverLocations()
        }
    }

    // Функции для зума карты
    private func zoomIn() {
        let span = MKCoordinateSpan(latitudeDelta: region.span.latitudeDelta / 2, longitudeDelta: region.span.longitudeDelta / 2)
        region.span = span
    }

    private func zoomOut() {
        let span = MKCoordinateSpan(latitudeDelta: region.span.latitudeDelta * 2, longitudeDelta: region.span.longitudeDelta * 2)
        region.span = span
    }

    // Центрирование карты на заказе
    private func centerMapOnOrder(_ order: OrderItem) {
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

        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }

    private func fetchDriverLocations() {
        let db = Firestore.firestore()
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
}

func generateReadableOrderId(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd"
    let dateString = formatter.string(from: date)
    let uniqueNumber = Int.random(in: 1...999)
    return "\(dateString)-\(String(format: "%03d", uniqueNumber))"
}
