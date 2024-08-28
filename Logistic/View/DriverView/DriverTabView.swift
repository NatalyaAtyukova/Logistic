import SwiftUI
import Firebase
import MapKit
import CoreLocation
import FirebaseFirestore


//driverID

struct DriverTabView: View {
    @StateObject private var alertManager = AlertManager()
    @StateObject private var locationManager = LocationManager()
    @State private var orders: [OrderItem] = []
    @State private var driverLocations: [DriverLocation] = []
    
    let userID: String

    var body: some View {
        TabView {
            FindOrderView(alertManager: alertManager)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Список моих заказов")
                }
            ActiveOrders(alertManager: alertManager, orders: $orders, driverLocations: $driverLocations, locationManager: locationManager)
                .tabItem {
                    Image(systemName: "doc.text")
                    Text("Заказы в работе и карта")
                }
            ChatDriverView(alertManager: alertManager)
                .tabItem {
                    Image(systemName: "message")
                    Text("Чат")
                }
            
            UserProfileView(userID: userID, role: "driver") // Добавляем профиль
                .tabItem {
                    Label("Профиль", systemImage: "person.circle")
                }
        }
        .navigationBarTitle("Панель водителя")
        .onAppear {
            locationManager.requestLocationPermission()
            locationManager.startUpdatingLocation()
            fetchDriverLocations()
        }
    }

    func fetchDriverLocations() {
        let db = Firestore.firestore()
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
}





//Map









