import SwiftUI
import FirebaseFirestore
import Firebase

class ActiveOrdersViewModel: ObservableObject {
    @Published var orders: [OrderItem] = []
    @Published var driverLocations: [DriverLocation] = []
    
    func fetchOrders(alertManager: AlertManager) {
        let db = Firestore.firestore()
        db.collection("OrdersList")
            .whereField("driverID", isEqualTo: Auth.auth().currentUser?.uid ?? "")
            .addSnapshotListener { (snapshot, error) in
                if let error = error {
                    alertManager.showError(message: "Ошибка при получении заказов: \(error.localizedDescription)")
                    return
                }

                var fetchedOrders: [OrderItem] = []

                snapshot?.documents.forEach { document in
                    do {
                        let order = try document.data(as: OrderItem.self)
                        fetchedOrders.append(order)
                    } catch {
                        print("Error decoding order: \(error)")
                    }
                }

                DispatchQueue.main.async {
                    self.orders = fetchedOrders
                }
            }
    }

    func cancelOrder(_ order: OrderItem, alertManager: AlertManager) {
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

    func completeOrder(_ order: OrderItem, alertManager: AlertManager) {
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
