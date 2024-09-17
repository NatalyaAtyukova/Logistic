import SwiftUI
import MapKit

struct AdminTabView: View {
    @StateObject private var viewModel = AdminTabViewModel()
    @StateObject private var alertManager = AlertManager()
    @ObservedObject private var locationManager = LocationManager()  // Используем @ObservedObject вместо @StateObject
    
    @State private var selectedTab: Int = 0 // Добавляем переменную для отслеживания активной вкладки

    let userID: String

    var body: some View {
        TabView(selection: $selectedTab) { // Управляем вкладками через selectedTab
            NavigationView {
                OrdersListView(selectedOrder: $viewModel.currentOrder, selectedTab: $selectedTab, alertManager: alertManager)
                    .navigationTitle("Список заказов")
                    .navigationBarTitleDisplayMode(.inline)
                    .background(Color(.systemGroupedBackground))
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("Список заказов")
            }
            .tag(0) // Указываем тег для отслеживания текущей вкладки

            AddOrderView(alertManager: alertManager)
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Добавить заказ")
                }
                .tag(1)

            if let order = viewModel.currentOrder {
                VStack(spacing: 0) {
                    ZStack(alignment: .topTrailing) {
                        // Передаем объект viewModel в MapAdminView
                        MapAdminView(viewModel: viewModel.mapAdminViewModel, order: order)
                            .edgesIgnoringSafeArea(.all)
                            .shadow(radius: 10)
                        
                        VStack {
                            // Используем методы зума из viewModel
                            ZoomControlsView(zoomIn: viewModel.zoomIn, zoomOut: viewModel.zoomOut)
                                .padding(.top, 50)
                                .padding(.trailing, 10)
                        }
                    }

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
                .tag(2) // Тег для вкладки карты
                .onAppear {
                    viewModel.centerMapOnOrder(order) // Центрирование карты на заказе
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
                .tag(2) // Тег для вкладки карты
            }

            ChatAdminView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Чат")
                }
                .tag(3)

            UserProfileView(userID: userID, role: "admin")
                .tabItem {
                    Label("Профиль", systemImage: "person.crop.circle.fill")
                }
                .tag(4)
        }
        .accentColor(.blue)
        .onAppear {
            locationManager.requestLocationPermission() // Запрос разрешений на геолокацию
            locationManager.startUpdatingLocation() // Начало обновления геопозиции
            viewModel.fetchDriverLocations() // Получение данных о местоположении водителей
        }
    }
}
