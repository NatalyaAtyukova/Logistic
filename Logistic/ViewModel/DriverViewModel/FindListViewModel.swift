import SwiftUI
import FirebaseFirestore
import Firebase

class FindListViewModel: ObservableObject {
    @Published var orders: [OrderItem] = []
    @Published var showAlert = false
    @Published var alertMessage = ""

    func fetchOrders() {
        let db = Firestore.firestore()
        
        db.collection("OrdersList")
            .whereField("status", isEqualTo: "Новый")
            .getDocuments { (snapshot, error) in
                if let error = error {
                    self.alertMessage = "Ошибка при получении заказов: \(error.localizedDescription)"
                    self.showAlert = true
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.alertMessage = "Заказы не найдены"
                    self.showAlert = true
                    return
                }

                var fetchedOrders: [OrderItem] = []
                for document in documents {
                    do {
                        let order = try document.data(as: OrderItem.self)
                        fetchedOrders.append(order)
                    } catch {
                        print("Error decoding order: \(error)")
                    }
                }

                DispatchQueue.main.async {
                    self.orders = fetchedOrders
                    print("Fetched \(fetchedOrders.count) orders from Firestore")
                }
            }
    }

    func takeOrder(orderID: String, currentUser: User) {
        let db = Firestore.firestore()

        db.collection("DriverProfiles").document(currentUser.uid).getDocument { (document, error) in
            if let document = document, document.exists {
                let driverData = document.data()

                if let firstName = driverData?["firstName"] as? String,
                   let lastName = driverData?["lastName"] as? String {
                    
                    let driverName = "\(firstName) \(lastName)"

                    db.collection("OrdersList").document(orderID).updateData([
                        "driverID": currentUser.uid,
                        "driverName": driverName,
                        "status": "В пути"
                    ]) { error in
                        if let error = error {
                            self.alertMessage = "Ошибка при взятии заказа в работу: \(error.localizedDescription)"
                            self.showAlert = true
                        } else {
                            self.alertMessage = "Заказ успешно взят в работу"
                            self.showAlert = true
                        }
                    }
                } else {
                    self.alertMessage = "Не удалось получить имя водителя"
                    self.showAlert = true
                }
            } else {
                self.alertMessage = "Документ водителя не найден"
                self.showAlert = true
            }
        }
    }

    func getCityName(from address: String) -> String {
        let components = address.split(separator: ",")
        return components.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? address
    }

    func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
}
