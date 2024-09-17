import SwiftUI
import Firebase

struct FindListView: View {
    @ObservedObject var alertManager: AlertManager
    var currentUser: UserInfo
    @Binding var orders: [OrderItem]

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if orders.isEmpty {
                    Text("Заказы не найдены")
                        .foregroundColor(.red)
                        .font(.title3)
                        .padding()
                        .transition(.opacity) // Плавный переход исчезновения
                } else {
                    List(orders.filter { $0.status == "Новый" }) { order in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading) {
                                    // Выводим номер заказа
                                    Text("Заказ #: \(order.id)")
                                        .font(.headline)
                                        .foregroundColor(.blue)

                                    // Информация о маршруте
                                    Text("Откуда: \(getCityName(from: order.senderAddress))")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Text("Куда: \(getCityName(from: order.recipientAddress))")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)

                                    // Другая информация
                                    Text("Компания: \(order.recipientCompany)")
                                        .font(.footnote)
                                    Text("Тип груза: \(order.cargoType)")
                                        .font(.footnote)
                                    Text("Вес: \(order.cargoWeight) кг")
                                        .font(.footnote)
                                    Text("Срок: \(formatDate(order.deliveryDeadline))")
                                        .font(.footnote)
                                        .foregroundColor(.red) // Выделим крайний срок доставки
                                }
                                Spacer()

                                // Иконка типа груза
                                Image(systemName: "shippingbox.fill")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.blue)
                            }

                            // Кнопка "Взять в работу"
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
                                .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.green]), startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(12)
                                .shadow(radius: 5)
                            }
                            .buttonStyle(PlainButtonStyle())  // Убираем системный эффект кнопки
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(15)
                        .shadow(color: Color.gray.opacity(0.4), radius: 5, x: 0, y: 5)
                        .padding(.horizontal)
                        .contentShape(Rectangle())
                    }
                    .listStyle(PlainListStyle())
                    .animation(.default) // Плавная анимация списка
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
            .background(Color.white.edgesIgnoringSafeArea(.all)) // Устанавливаем белый фон без закруглений
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

    func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
}
