import SwiftUI
import Firebase
import FirebaseFirestore

class OrdersListViewModel: ObservableObject {
    @Published var orders: [OrderItem] = []
    @Published var selectedStatus: String = "Все"
    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var isError: Bool = false
    @Published var editingOrder: OrderItem? = nil
    @Published var isLoading: Bool = true

    private let db = Firestore.firestore()

    // Инициализатор ViewModel, который сразу вызывает загрузку заказов
    init() {
        getOrders()
    }

    // Получение заказов из Firestore с реальным временем через addSnapshotListener
    func getOrders() {
        guard let currentUser = Auth.auth().currentUser else {
            self.showError(message: "Пользователь не авторизован")
            return
        }

        self.isLoading = true

        db.collection("OrdersList")
            .whereField("adminID", isEqualTo: currentUser.uid)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    self.showError(message: "Ошибка при получении заказов: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    self.showError(message: "Нет документов")
                    return
                }

                self.orders = documents.compactMap { document in
                    do {
                        let order = try document.data(as: OrderItem.self)
                        return order
                    } catch {
                        print("Ошибка при декодировании заказа: \(error)")
                        return nil
                    }
                }

                // После загрузки данных сбрасываем флаг загрузки
                self.isLoading = false
            }
    }

    // Фильтрация заказов по статусу
    var filteredOrders: [OrderItem] {
        if selectedStatus == "Все" {
            return orders
        } else {
            return orders.filter { $0.status == selectedStatus }
        }
    }

    // Отображение ошибки
    func showError(message: String) {
        self.alertMessage = message
        self.isError = true
        self.showAlert = true
        self.isLoading = false
    }

    // Форматирование даты
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}   
