import SwiftUI
import FirebaseFirestore

struct OrdersListView: View {
    @ObservedObject private var viewModel = OrdersListViewModel()
    @Binding var selectedOrder: OrderItem?
    @Binding var selectedTab: Int // Добавляем binding для отслеживания текущей вкладки
    @ObservedObject var alertManager: AlertManager

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Статус", selection: $viewModel.selectedStatus) {
                    Text("Все").tag("Все")
                    Text("Новый").tag("Новый")
                    Text("В пути").tag("В пути")
                    Text("Доставлено").tag("Доставлено")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                if viewModel.isLoading {
                    ProgressView("Загрузка заказов...")
                        .padding()
                } else if viewModel.filteredOrders.isEmpty {
                    Text("Нет доступных заказов")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(viewModel.filteredOrders) { order in
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
                                            Text(viewModel.formatDate(order.deliveryDeadline))
                                                .bold()
                                        }
                                    }

                                    Divider()

                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("Получатель: \(order.recipientCompany)")
                                        Text("Откуда: \(order.senderAddress)")
                                        Text("Куда: \(order.recipientAddress)")
                                        Text("Водитель: \(order.driverName)")
                                        Text("Информация о заказе: \(order.orderInfo)")
                                        Text("Статус: \(order.status)")
                                    }

                                    HStack {
                                        Button(action: {
                                            self.selectedOrder = order
                                            self.selectedTab = 2 // Переключение на вкладку с картой
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

                                        Button(action: {
                                            self.viewModel.editingOrder = order
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
                                    .frame(maxWidth: .infinity)
                                    .padding([.leading, .trailing], 8)
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
            .sheet(item: $viewModel.editingOrder) { order in
                if let orderBinding = Binding($viewModel.editingOrder) {
                    EditOrderView(order: orderBinding, alertManager: self.alertManager)
                }
            }
            .alert(isPresented: $viewModel.showAlert) {
                let title = viewModel.isError ? "Ошибка" : "Успешно"
                return Alert(title: Text(title), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        }
    }
}
