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
            VStack(spacing: 0) {
                if orders.isEmpty {
                    Text("Нет активных заказов")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 10) { // Убираем лишние отступы и делаем фон шире
                            ForEach(orders) { order in
                                VStack(alignment: .leading, spacing: 15) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("Заказ #: \(order.id)")
                                                .font(.headline)
                                                .foregroundColor(.blue)
                                            Text("Тип груза: \(order.cargoType)")
                                            Text("Вес: \(order.cargoWeight) кг")
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing) {
                                            Text("Крайний срок:")
                                            Text(formatDate(order.deliveryDeadline))
                                                .bold()
                                        }
                                    }

                                    Divider()

                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("Откуда: \(order.senderAddress)")
                                        Text("Куда: \(order.recipientAddress)")
                                        Text("Водитель: \(order.driverName)")
                                        Text("Информация о заказе: \(order.orderInfo)")  
                                        Text("Статус: \(order.status)")  
                                    }

                                    HStack {
                                        // Показать заказ на карте
                                        Button(action: {
                                            self.selectedOrder = order
                                            self.showingOrderOnMap = true
                                        }) {
                                            HStack {
                                                Image(systemName: "map")
                                                Text("Показать на карте")
                                            }
                                            .font(.system(size: 16, weight: .medium))
                                            .frame(maxWidth: .infinity) // Кнопка на всю ширину
                                            .padding()
                                            .foregroundColor(.white)
                                            .background(Color.blue)
                                            .cornerRadius(8)
                                        }

                                        // Действия с заказом
                                        Button(action: {
                                            self.selectedOrder = order
                                            self.showingActionSheet = true
                                        }) {
                                            HStack {
                                                Image(systemName: "ellipsis")
                                                Text("Действия")
                                            }
                                            .font(.system(size: 16, weight: .medium))
                                            .frame(maxWidth: .infinity) // Кнопка на всю ширину
                                            .padding()
                                            .foregroundColor(.white)
                                            .background(Color.green)
                                            .cornerRadius(8)
                                        }
                                    }
                                    .frame(maxWidth: .infinity) // Обе кнопки на всю ширину блока
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12) // Небольшие закругления у карточек
                                .shadow(color: Color.gray.opacity(0.4), radius: 5, x: 0, y: 5)
                                .padding(.horizontal) // Увеличиваем горизонтальные отступы для расширения карточки
                            }
                        }
                    }
                }
                Spacer()
            }
            .navigationBarTitle("Мои заказы", displayMode: .inline)
            .alert(isPresented: $alertManager.showAlert) {
                Alert(
                    title: Text("Сообщение"),
                    message: Text(alertManager.alertMessage),
                    dismissButton: .default(Text("OK")) {
                        alertManager.showAlert = false
                    }
                )
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
            .onAppear {
                fetchOrders()
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
