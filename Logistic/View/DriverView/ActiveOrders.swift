import SwiftUI
import Firebase
import MapKit
import CoreLocation
import FirebaseFirestore


struct ActiveOrders: View {
    @ObservedObject var alertManager: AlertManager
    @Binding var orders: [OrderItem]
    @Binding var driverLocations: [DriverLocation]
    @ObservedObject var locationManager: LocationManager

    @State private var selectedOrder: OrderItem?
    @State private var showingActionSheet = false
    @State private var showingOrderOnMap = false

    var body: some View {
        NavigationView {
            VStack {
                // Список заказов
                List {
                    ForEach(orders) { order in
                        OrderRow(order: order,
                                 onSelect: {
                                     self.selectedOrder = order
                                     self.showingOrderOnMap = true
                                 },
                                 onActions: {
                                     self.selectedOrder = order
                                     self.showingActionSheet = true
                                 })
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .onAppear {
                    fetchOrders()
                }
            }
            .navigationBarTitle("Мои заказы")
            .alert(isPresented: $alertManager.showAlert) {
                Alert(title: Text("Сообщение"),
                      message: Text(alertManager.alertMessage),
                      dismissButton: .default(Text("OK")) {
                          alertManager.showAlert = false
                      })
            }
            .actionSheet(isPresented: $showingActionSheet) {
                ActionSheet(
                    title: Text("Выберите действие"),
                    message: Text("Выберите действие для заказа: \(selectedOrder?.orderInfo ?? "")"),
                    buttons: [
                        .destructive(Text("Отменить заказ")) {
                            if let selectedOrder = selectedOrder {
                                cancelOrder(selectedOrder)
                            }
                        },
                        .default(Text("Завершить доставку")) {
                            if let selectedOrder = selectedOrder {
                                completeOrder(selectedOrder)
                            }
                        },
                        .cancel()
                    ]
                )
            }
            .sheet(isPresented: $showingOrderOnMap) {
                if let selectedOrder = selectedOrder {
                    MapViewWithOrder(order: selectedOrder, isPresented: $showingOrderOnMap, region: $locationManager.region)
                }
            }
        }
    }


    func fetchOrders() {
        getDriversOrders(alertManager: alertManager) { fetchedOrders, error in
            if let error = error {
                alertManager.showError(message: "Ошибка при получении заказов: \(error.localizedDescription)")
                return
            }

            if let fetchedOrders = fetchedOrders {
                self.orders = fetchedOrders
            }
        }
    }

    func cancelOrder(_ order: OrderItem) {
        let db = Firestore.firestore()

        db.collection("OrdersList").document(order.id).updateData([
            "status": "Отменен водителем",
            "driverID": "",
            "driverName": "Не нашли водителя"
        ]) { error in
            if let error = error {
                alertManager.showError(message: "Ошибка при отмене заказа: \(error.localizedDescription)")
            } else {
                alertManager.showSuccess(message: "Заказ успешно отменен")
            }
        }
    }

    func completeOrder(_ order: OrderItem) {
        let db = Firestore.firestore()
        
        db.collection("OrdersList").document(order.id).updateData([
            "status": "Доставлено"
        ]) { error in
            if let error = error {
                alertManager.showError(message: "Ошибка при завершении заказа: \(error.localizedDescription)")
            } else {
                alertManager.showSuccess(message: "Заказ успешно завершен")
            }
        }
    }
}
