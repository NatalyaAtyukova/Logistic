import SwiftUI
import Firebase
import MapKit
import CoreLocation
import FirebaseFirestore


struct FindListView: View {
    @ObservedObject var alertManager: AlertManager
    var currentUser: UserInfo
    var orders: [OrderItem]
    
    var body: some View {
        VStack {
            if orders.isEmpty {
                Text("Заказы не найдены")
                    .foregroundColor(.red)
                    .padding()
            } else {
                List(orders.filter { $0.status == "Новый" }) { order in
                    VStack(alignment: .leading) {
                        Text("Откуда: \(getCityName(from: order.senderAddress))")
                        Text("Куда: \(getCityName(from: order.recipientAddress))")
                        Text("Компания-получатель: \(order.recipientCompany)")
                        Text("Тип груза: \(order.cargoType)")
                        Text("Информация о заказе: \(order.orderInfo)")
                        Text("Вес груза: \(order.cargoWeight)")
                        Text("Крайний срок доставки: \(formatDate(order.deliveryDeadline))")
                        
                        Button("Взять в работу") {
                            takeOrder(orderID: order.id)
                        }
                    }
                }
            }
        }
        .navigationBarTitle("Поиск заказа")
        .alert(isPresented: $alertManager.showAlert) {
            Alert(title: Text("Сообщение"),
                  message: Text(alertManager.alertMessage),
                  dismissButton: .default(Text("OK")) {
                      alertManager.showAlert = false
                  })
        }
        .onAppear {
            print("Displaying orders: \(orders)")
        }
    }
    
    func takeOrder(orderID: String) {
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
                            alertManager.showError(message: "Ошибка при взятии заказа в работу: \(error.localizedDescription)")
                        } else {
                            alertManager.showSuccess(message: "Заказ успешно взят в работу")
                        }
                    }
                } else {
                    alertManager.showError(message: "Не удалось получить имя водителя")
                }
            } else {
                alertManager.showError(message: "Документ водителя не найден")
            }
        }
    }
    
    func getCityName(from address: String) -> String {
        let components = address.split(separator: ",")
        return components.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? address
    }
}

func formatDate(_ date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "ru_RU")
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .short
    return dateFormatter.string(from: date)
}
