import SwiftUI
import MapKit

struct ActiveOrders: View {
    @ObservedObject var alertManager: AlertManager
    @ObservedObject var viewModel: ActiveOrdersViewModel

    @State private var selectedOrder: OrderItem?
    @State private var showingOrderOnMap = false
    @State private var showingActionSheet = false
    @State private var selectedFilter: OrderStatusFilter = .inTransit
    @State private var region = MKCoordinateRegion()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Статус заказов", selection: $selectedFilter) {
                    Text("В пути").tag(OrderStatusFilter.inTransit)
                    Text("Доставлено").tag(OrderStatusFilter.delivered)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                if filteredOrders.isEmpty {
                    Text("Нет заказов")
                        .foregroundColor(.gray)
                        .font(.title3)
                        .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(filteredOrders) { order in
                                VStack(alignment: .leading, spacing: 15) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text("Заказ #: \(order.id)")
                                                .font(.headline)
                                                .foregroundColor(.blue)
                                            Text("Тип груза: \(order.cargoType)")
                                                .font(.footnote)
                                                .foregroundColor(.gray)
                                            Text("Вес: \(order.cargoWeight) кг")
                                                .font(.footnote)
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 5) {
                                            Text("Крайний срок:")
                                                .font(.footnote)
                                            Text(formatDate(order.deliveryDeadline))
                                                .bold()
                                                .foregroundColor(.red)
                                        }
                                    }

                                    Divider()

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Откуда: \(order.senderAddress)")
                                            .font(.subheadline)
                                        Text("Куда: \(order.recipientAddress)")
                                            .font(.subheadline)
                                        Text("Водитель: \(order.driverName)")
                                            .font(.footnote)
                                        Text("Информация о заказе: \(order.orderInfo)")
                                            .font(.footnote)
                                        Text("Статус: \(order.status)")
                                            .font(.footnote)
                                            .foregroundColor(order.status == "В пути" ? .green : .orange)
                                    }

                                    HStack(spacing: 10) {
                                        Button(action: {
                                            self.selectedOrder = order
                                            self.showingOrderOnMap = true
                                        }) {
                                            HStack {
                                                Image(systemName: "map.fill")
                                                Text("Показать на карте")
                                            }
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.green]), startPoint: .leading, endPoint: .trailing))
                                            .cornerRadius(12)
                                            .shadow(radius: 5)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .disabled(order.status == "Доставлено")

                                        Button(action: {
                                            self.selectedOrder = order
                                            self.showingActionSheet = true
                                        }) {
                                            HStack {
                                                Image(systemName: "ellipsis.circle.fill")
                                                Text("Действия")
                                            }
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(Color.green)
                                            .cornerRadius(12)
                                            .shadow(radius: 5)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .disabled(order.status == "Доставлено")
                                        .actionSheet(isPresented: $showingActionSheet) {
                                            ActionSheet(
                                                title: Text("Действия с заказом"),
                                                buttons: [
                                                    .destructive(Text("Отменить заказ")) {
                                                        if let selectedOrder = selectedOrder {
                                                            viewModel.cancelOrder(selectedOrder, alertManager: alertManager)
                                                        }
                                                    },
                                                    .default(Text("Завершить заказ")) {
                                                        if let selectedOrder = selectedOrder {
                                                            viewModel.completeOrder(selectedOrder, alertManager: alertManager)
                                                        }
                                                    },
                                                    .cancel()
                                                ]
                                            )
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(15)
                                .shadow(color: Color.gray.opacity(0.4), radius: 5, x: 0, y: 5)
                                .padding(.horizontal)
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.3))
                            }
                        }
                    }
                }
                Spacer()
            }
            .navigationBarTitle("Мои заказы", displayMode: .inline)
            .sheet(isPresented: $showingOrderOnMap) {
                if let selectedOrder = selectedOrder {
                    MapViewWithOrder(order: selectedOrder, isPresented: $showingOrderOnMap, region: $region)
                }
            }
            .onAppear {
                viewModel.fetchOrders(alertManager: alertManager)
            }
        }
    }

    private var filteredOrders: [OrderItem] {
        switch selectedFilter {
        case .inTransit:
            return viewModel.orders.filter { $0.status == "В пути" }
        case .delivered:
            return viewModel.orders.filter { $0.status == "Доставлено" }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
}

enum OrderStatusFilter {
    case inTransit
    case delivered
}
