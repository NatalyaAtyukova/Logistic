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
        NavigationView {
            VStack(spacing: 16) {
                if orders.isEmpty {
                    Text("Заказы не найдены")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List(orders.filter { $0.status == "Новый" }) { order in
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Откуда: \(getCityName(from: order.senderAddress))")
                                .font(.headline)
                            Text("Куда: \(getCityName(from: order.recipientAddress))")
                            Text("Компания-получатель: \(order.recipientCompany)")
                            Text("Тип груза: \(order.cargoType)")
                            Text("Информация о заказе: \(order.orderInfo)")
                            Text("Вес груза: \(order.cargoWeight) кг")
                            Text("Крайний срок доставки: \(formatDate(order.deliveryDeadline))")

                            Button(action: {
                                takeOrder(orderID: order.id)
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Взять в работу")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .gray.opacity(0.4), radius: 5, x: 0, y: 5)
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarTitle("Поиск заказа", displayMode: .inline)
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
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
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
