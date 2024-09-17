import SwiftUI
import Firebase
import FirebaseFirestore
import CoreLocation
import Foundation
import Combine

class AddOrderViewModel: ObservableObject {
    @Published var cargoTypes: [String] = ["Обычный", "Хрупкий", "Опасный"]
    @Published var selectedCargoType: String = "Обычный"
    @Published var deliveryDeadline: Date = Date()
    @Published var orderInfo: String = ""
    @Published var cargoWeight: String = ""
    @Published var recipientCompany: String = ""
    @Published var senderAddress: String = ""
    @Published var recipientAddress: String = ""
    @Published var selectedStatus: String = "Новый"
    @Published var driverName: String = "Не нашли водителя"
    @Published var statuses: [String] = ["Новый", "В пути", "Доставлено"]
    
    @Published var senderCoordinate: CLLocationCoordinate2D?
    @Published var recipientCoordinate: CLLocationCoordinate2D?
    @Published var senderSuggestions: [DaDataSuggestion] = []
    @Published var recipientSuggestions: [DaDataSuggestion] = []
    @Published var isShowingSenderSuggestions: Bool = false
    @Published var isShowingRecipientSuggestions: Bool = false
    
    @Published var showingAlert: Bool = false
    @Published var alertMessage: String = ""
    
    @ObservedObject var alertManager: AlertManager

    init(alertManager: AlertManager) {
        self.alertManager = alertManager
    }

    func addOrder() {
        let db = Firestore.firestore()

        // Проверка координат отправления и получения
        guard let senderCoordinate = senderCoordinate, let recipientCoordinate = recipientCoordinate else {
            alertManager.showError(message: "Необходимо выбрать адрес отправления и получения.")
            return
        }

        // Получаем текущего пользователя внутри метода
        guard let currentUser = Auth.auth().currentUser else {
            alertManager.showError(message: "Ошибка: пользователь не авторизован.")
            return
        }

        let newOrderId = generateReadableOrderId(for: Date())
        
        let orderData: [String: Any] = [
            "id": newOrderId,
            "cargoType": selectedCargoType,
            "deliveryDeadline": deliveryDeadline,
            "orderInfo": orderInfo,
            "cargoWeight": cargoWeight,
            "recipientCompany": recipientCompany,
            "senderAddress": senderAddress,
            "recipientAddress": recipientAddress,
            "senderLatitude": senderCoordinate.latitude,
            "senderLongitude": senderCoordinate.longitude,
            "recipientLatitude": recipientCoordinate.latitude,
            "recipientLongitude": recipientCoordinate.longitude,
            "status": selectedStatus,
            "driverName": driverName,
            "adminID": currentUser.uid
        ]

        // Сохранение заказа в Firestore
        db.collection("OrdersList").document(newOrderId).setData(orderData) { error in
            if let error = error {
                self.alertManager.showError(message: "Ошибка при добавлении заказа: \(error.localizedDescription)")
            } else {
                self.alertMessage = "Заказ успешно добавлен!"
                self.showingAlert = true
                self.clearFields()
            }
        }
    }

    // Очистка полей после успешного добавления заказа
    func clearFields() {
        selectedCargoType = "Обычный"
        deliveryDeadline = Date()
        orderInfo = ""
        cargoWeight = ""
        recipientCompany = ""
        senderAddress = ""
        recipientAddress = ""
        senderCoordinate = nil
        recipientCoordinate = nil
        selectedStatus = "Новый"
        driverName = "Не нашли водителя"
    }

    // Генерация уникального ID заказа
    func generateReadableOrderId(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dateString = formatter.string(from: date)
        let uniqueNumber = Int.random(in: 1...999)
        return "\(dateString)-\(String(format: "%03d", uniqueNumber))"
    }
}
