import Foundation
import Firebase
import FirebaseFirestore
import CoreLocation

class EditOrderViewModel: ObservableObject {
    @Published var cargoTypes: [String] = ["Обычный", "Хрупкий", "Опасный"] // Массив типов груза
    @Published var cargoType = ""
    @Published var cargoWeight = ""
    @Published var deliveryDeadline = Date()
    @Published var orderInfo = ""
    @Published var recipientCompany = ""
    @Published var senderAddress = ""
    @Published var recipientAddress = ""
    @Published var driverName = ""
    @Published var status = ""
    
    @Published var statuses: [String] = ["Новый", "В пути", "Доставлено"] // Массив статусов
    
    @Published var senderCoordinate: CLLocationCoordinate2D?
    @Published var recipientCoordinate: CLLocationCoordinate2D?
    @Published var senderSuggestions: [DaDataSuggestion] = []
    @Published var recipientSuggestions: [DaDataSuggestion] = []
    @Published var isShowingSenderSuggestions = false
    @Published var isShowingRecipientSuggestions = false
    
    @Published var showingAlert = false
    @Published var alertMessage = ""
    
    private let order: OrderItem
    private let alertManager: AlertManager

    init(order: OrderItem, alertManager: AlertManager) {
        self.order = order
        self.alertManager = alertManager
        loadOrderData()
    }

    func loadOrderData() {
        // Загружаем данные текущего заказа в модель
        self.cargoType = order.cargoType
        self.cargoWeight = order.cargoWeight
        self.deliveryDeadline = order.deliveryDeadline
        self.orderInfo = order.orderInfo
        self.recipientCompany = order.recipientCompany
        self.senderAddress = order.senderAddress
        self.recipientAddress = order.recipientAddress
        self.driverName = order.driverName
        self.status = order.status
        self.senderCoordinate = CLLocationCoordinate2D(latitude: order.senderLatitude, longitude: order.senderLongitude)
        self.recipientCoordinate = CLLocationCoordinate2D(latitude: order.recipientLatitude, longitude: order.recipientLongitude)
    }
    
    func saveChanges() {
        let db = Firestore.firestore()
        let orderRef = db.collection("OrdersList").document(order.id)
        
        orderRef.updateData([
            "cargoType": cargoType,
            "cargoWeight": cargoWeight,
            "deliveryDeadline": deliveryDeadline,
            "orderInfo": orderInfo,
            "recipientCompany": recipientCompany,
            "senderAddress": senderAddress,
            "recipientAddress": recipientAddress,
            "driverName": driverName,
            "status": status,
            "senderLatitude": senderCoordinate?.latitude ?? 0.0,
            "senderLongitude": senderCoordinate?.longitude ?? 0.0,
            "recipientLatitude": recipientCoordinate?.latitude ?? 0.0,
            "recipientLongitude": recipientCoordinate?.longitude ?? 0.0
        ]) { error in
            if let error = error {
                self.alertManager.showError(message: "Ошибка при обновлении документа: \(error.localizedDescription)")
            } else {
                self.alertManager.showSuccess(message: "Документ успешно обновлен")
                self.showingAlert = true
            }
        }
    }
}
