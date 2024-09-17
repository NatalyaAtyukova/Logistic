import SwiftUI
import MapKit

struct DriverTabView: View {
    @StateObject private var viewModel = DriverTabViewModel()
    @StateObject private var alertManager = AlertManager()
    @StateObject private var locationManager = LocationManager()
    
    let userID: String

    var body: some View {
        TabView {
            FindOrderView(alertManager: alertManager)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Список моих заказов")
                }
            // Передача alertManager в ActiveOrders
            ActiveOrders(alertManager: alertManager, viewModel: ActiveOrdersViewModel())
                .tabItem {
                    Image(systemName: "doc.text")
                    Text("Заказы в работе и карта")
                }
            ChatDriverView(alertManager: alertManager)
                .tabItem {
                    Image(systemName: "message")
                    Text("Чат")
                }
            UserProfileView(userID: userID, role: "driver")
                .tabItem {
                    Label("Профиль", systemImage: "person.circle")
                }
        }
        .navigationBarTitle("Панель водителя")
        .onAppear {
            locationManager.requestLocationPermission()
            locationManager.startUpdatingLocation()
            viewModel.fetchDriverLocations()
            viewModel.fetchOrders(for: userID)
        }
    }
}
