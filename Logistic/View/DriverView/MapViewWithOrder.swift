import SwiftUI
import Firebase
import MapKit
import CoreLocation
import FirebaseFirestore


struct MapViewWithOrder: View {
    var order: OrderItem
    @Binding var isPresented: Bool
    @Binding var region: MKCoordinateRegion

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Spacer()

                    Button(action: {
                        isPresented = false // Закрыть окно карты
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .imageScale(.large)
                            .padding()
                    }
                }

                VStack(alignment: .leading) {
                    Text("Откуда: \(order.senderAddress)")
                        .font(.headline)
                        .padding(.bottom, 2)
                    Text("Куда: \(order.recipientAddress)")
                        .font(.subheadline)
                        .padding(.bottom, 10)
                }
                .padding(.horizontal)
                .font(.system(size: 16)) // Единый стиль шрифта

                MapViewWithRoute(order: order, region: $region)
                    .edgesIgnoringSafeArea(.bottom) // Занимает всё доступное пространство
            }
            .navigationBarHidden(true) // Скрывает верхнюю панель навигации
        }
    }
}

func getDriversOrders(alertManager: AlertManager, completion: @escaping ([OrderItem]?, Error?) -> Void) {
    let db = Firestore.firestore()

    if let currentUser = Auth.auth().currentUser {
        db.collection("OrdersList")
            .whereField("driverID", isEqualTo: currentUser.uid)
            .whereField("status", isEqualTo: "В пути") // Добавлен фильтр по статусу "В пути"
            .getDocuments { (snapshot, error) in
                if let error = error {
                    alertManager.showError(message: "Ошибка при получении заказов: \(error.localizedDescription)")
                    completion(nil, error)
                    return
                }

                var fetchedOrders: [OrderItem] = []

                for document in snapshot!.documents {
                    let orderData = document.data()

                    // Извлечение данных и проверка наличия всех необходимых полей
                    guard
                        let id = orderData["id"] as? String,
                        let adminID = orderData["adminID"] as? String,
                        let cargoType = orderData["cargoType"] as? String,
                        let cargoWeight = orderData["cargoWeight"] as? String,
                        let deliveryDeadlineTimestamp = orderData["deliveryDeadline"] as? Timestamp,
                        let driverName = orderData["driverName"] as? String,
                        let orderInfo = orderData["orderInfo"] as? String,
                        let recipientAddress = orderData["recipientAddress"] as? String,
                        let recipientCompany = orderData["recipientCompany"] as? String,
                        let recipientLatitude = orderData["recipientLatitude"] as? Double,
                        let recipientLongitude = orderData["recipientLongitude"] as? Double,
                        let senderAddress = orderData["senderAddress"] as? String,
                        let senderLatitude = orderData["senderLatitude"] as? Double,
                        let senderLongitude = orderData["senderLongitude"] as? Double,
                        let status = orderData["status"] as? String
                    else {
                        // Пропустить запись, если какое-то из полей отсутствует или неверного типа
                        continue
                    }

                    // Преобразование Timestamp в Date
                    let deliveryDeadline: Date
                    if let timestamp = deliveryDeadlineTimestamp as? Timestamp {
                        deliveryDeadline = timestamp.dateValue()
                    } else {
                        // В случае ошибки извлечения даты
                        continue
                    }

                    let order = OrderItem(
                        id: id,
                        adminID: adminID,
                        cargoType: cargoType,
                        cargoWeight: cargoWeight,
                        deliveryDeadline: deliveryDeadline,
                        driverName: driverName,
                        orderInfo: orderInfo,
                        recipientAddress: recipientAddress,
                        recipientCompany: recipientCompany,
                        recipientLatitude: recipientLatitude,
                        recipientLongitude: recipientLongitude,
                        senderAddress: senderAddress,
                        senderLatitude: senderLatitude,
                        senderLongitude: senderLongitude,
                        status: status
                    )

                    fetchedOrders.append(order)
                }

                DispatchQueue.main.async {
                    completion(fetchedOrders, nil)
                }
            }
    }
}
