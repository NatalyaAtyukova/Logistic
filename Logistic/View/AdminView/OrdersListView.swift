import SwiftUI
import Firebase
import FirebaseFirestore
import MapKit
import CoreLocation

struct OrdersListView: View {
    @State private var orders: [OrderItem] = []
    @Binding var selectedOrder: OrderItem?
    @ObservedObject var alertManager: AlertManager
    @State private var selectedStatus: String = "Все"
    @State private var editingOrder: OrderItem? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Статус", selection: $selectedStatus) {
                    Text("Все").tag("Все")
                    Text("Новый").tag("Новый")
                    Text("В пути").tag("В пути")
                    Text("Доставлено").tag("Доставлено")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .offset(y: -40) // Сдвигаем вверх Picker для уменьшения отступа
                
                if filteredOrders.isEmpty {
                    Text("Нет доступных заказов")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredOrders) { order in
                                VStack(alignment: .leading, spacing: 12) {
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
                                        Text("Получатель: \(order.recipientCompany)")
                                        Text("Откуда: \(order.senderAddress)")
                                        Text("Куда: \(order.recipientAddress)")
                                        Text("Водитель: \(order.driverName)")
                                    }

                                    HStack {
                                        // Кнопка выбора заказа
                                        Button(action: {
                                            self.selectedOrder = order
                                        }) {
                                            HStack {
                                                Image(systemName: "checkmark.circle.fill")
                                                Text("Выбрать")
                                            }
                                            .font(.system(size: 16, weight: .medium))
                                            .padding()
                                            .foregroundColor(.white)
                                            .background(Color.blue)
                                            .cornerRadius(8)
                                        }

                                        // Кнопка редактирования заказа
                                        Button(action: {
                                            self.editingOrder = order
                                        }) {
                                            HStack {
                                                Image(systemName: "pencil")
                                                Text("Редактировать")
                                            }
                                            .font(.system(size: 16, weight: .medium))
                                            .padding()
                                            .foregroundColor(.white)
                                            .background(Color.green)
                                            .cornerRadius(8)
                                        }
                                    }
                                    .frame(maxWidth: .infinity) // Убедитесь, что HStack занимает всю доступную ширину
                                    .padding([.leading, .trailing], 8) // Добавляем горизонтальные отступы, чтобы кнопки не прилипали к краям
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .gray.opacity(0.4), radius: 5, x: 0, y: 5)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                Spacer()
            }
            .navigationBarTitle("Список заказов", displayMode: .inline)
            .onAppear {
                getOrders()
            }
            .sheet(item: self.$editingOrder) { order in
                EditOrderView(order: self.$editingOrder, alertManager: self.alertManager)
            }
            .alert(isPresented: $alertManager.showAlert) {
                let title = alertManager.isError ? "Ошибка" : "Успешно"
                return Alert(title: Text(title), message: Text(alertManager.alertMessage), dismissButton: .default(Text("OK")))
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        }
    }

    var filteredOrders: [OrderItem] {
        if selectedStatus == "Все" {
            return orders
        } else {
            return orders.filter { $0.status == selectedStatus }
        }
    }

    func getOrders() {
        let db = Firestore.firestore()

        if let currentUser = Auth.auth().currentUser {
            db.collection("OrdersList")
                .whereField("adminID", isEqualTo: currentUser.uid)
                .addSnapshotListener { (snapshot, error) in
                    if let error = error {
                        alertManager.showError(message: "Ошибка при получении заказов: \(error.localizedDescription)")
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        print("No documents in snapshot")
                        return
                    }

                    self.orders = documents.compactMap { document in
                        do {
                            let order = try document.data(as: OrderItem.self)
                            return order
                        } catch {
                            print("Error decoding order: \(error)")
                            return nil
                        }
                    }
                }
        }
    }

    // Функция для форматирования даты
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
