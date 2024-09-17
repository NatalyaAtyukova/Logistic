import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore

class FindOrderViewModel: ObservableObject {
    @Published var senderCity: String = "" {
        didSet {
            fetchSenderCitySuggestions(for: senderCity) // Загружаем предложения из Firestore
            filterCitySuggestions(for: senderCity, isSenderCity: true) // Фильтрация предложений
        }
    }
    @Published var recipientCity: String = "" {
        didSet {
            fetchRecipientCitySuggestions(for: recipientCity) // Загружаем предложения из Firestore
            filterCitySuggestions(for: recipientCity, isSenderCity: false) // Фильтрация предложений
        }
    }
    @Published var orders: [OrderItem] = []
    @Published var isShowingOrdersList = false
    @Published var senderCitySuggestions: [String] = []
    @Published var recipientCitySuggestions: [String] = []
    @Published var filteredSenderCitySuggestions: [String] = []
    @Published var filteredRecipientCitySuggestions: [String] = []
    @Published var isShowingSenderCitySuggestions = false
    @Published var isShowingRecipientCitySuggestions = false
    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false
    
    private var db = Firestore.firestore()
    
    func searchOrders() {
        print("Searching for orders with senderCity: \(senderCity), recipientCity: \(recipientCity), and status: 'Новый'")

        db.collection("OrdersList")
            .whereField("status", isEqualTo: "Новый")
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    self.alertMessage = "Ошибка при поиске заказов: \(error.localizedDescription)"
                    self.showAlert = true
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    self.alertMessage = "Заказы не найдены"
                    self.showAlert = true
                    return
                }

                let orders = documents.compactMap { queryDocumentSnapshot -> OrderItem? in
                    let data = queryDocumentSnapshot.data()

                    guard
                        let id = data["id"] as? String,
                        let adminID = data["adminID"] as? String,
                        let cargoType = data["cargoType"] as? String,
                        let cargoWeight = data["cargoWeight"] as? String,
                        let deliveryDeadlineTimestamp = data["deliveryDeadline"] as? Timestamp,
                        let driverName = data["driverName"] as? String,
                        let orderInfo = data["orderInfo"] as? String,
                        let recipientAddress = data["recipientAddress"] as? String,
                        let recipientCompany = data["recipientCompany"] as? String,
                        let recipientLatitude = data["recipientLatitude"] as? Double,
                        let recipientLongitude = data["recipientLongitude"] as? Double,
                        let senderAddress = data["senderAddress"] as? String,
                        let senderLatitude = data["senderLatitude"] as? Double,
                        let senderLongitude = data["senderLongitude"] as? Double,
                        let status = data["status"] as? String,
                        status == "Новый" // Фильтрация по статусу "Новый"
                    else {
                        return nil
                    }

                    // Проверка, соответствует ли город отправления и назначения введённым данным
                    if !senderAddress.lowercased().contains(self.senderCity.lowercased()) ||
                        !recipientAddress.lowercased().contains(self.recipientCity.lowercased()) {
                        return nil
                    }

                    let deliveryDeadline = deliveryDeadlineTimestamp.dateValue()

                    return OrderItem(
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
                }

                self.orders = orders
                self.isShowingOrdersList = true
            }
    }

    func fetchSenderCitySuggestions(for senderCity: String) {
        db.collection("OrdersList")
            .whereField("senderAddress", isGreaterThanOrEqualTo: senderCity)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching sender city suggestions: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No documents found for sender city suggestions")
                    return
                }
                
                let senderCities = Set(documents.compactMap { $0.data()["senderAddress"] as? String }.flatMap { self.extractCitiesAndRegions(from: $0) })
                
                self.senderCitySuggestions = Array(senderCities)
                // Фильтруем предложения после их получения
                self.filterCitySuggestions(for: senderCity, isSenderCity: true)
            }
    }
    
    func fetchRecipientCitySuggestions(for recipientCity: String) {
        db.collection("OrdersList")
            .whereField("recipientAddress", isGreaterThanOrEqualTo: recipientCity)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching recipient city suggestions: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No documents found for recipient city suggestions")
                    return
                }
                
                let recipientCities = Set(documents.compactMap { $0.data()["recipientAddress"] as? String }.flatMap { self.extractCitiesAndRegions(from: $0) })
                
                self.recipientCitySuggestions = Array(recipientCities)
                // Фильтруем предложения после их получения
                self.filterCitySuggestions(for: recipientCity, isSenderCity: false)
            }
    }
    
    // Фильтрация предложений по введенному пользователем тексту
    private func filterCitySuggestions(for city: String, isSenderCity: Bool) {
        if city.isEmpty {
            if isSenderCity {
                filteredSenderCitySuggestions = []
            } else {
                filteredRecipientCitySuggestions = []
            }
            return
        }

        if isSenderCity {
            filteredSenderCitySuggestions = senderCitySuggestions.filter { $0.lowercased().contains(city.lowercased()) }
            isShowingSenderCitySuggestions = !filteredSenderCitySuggestions.isEmpty
        } else {
            filteredRecipientCitySuggestions = recipientCitySuggestions.filter { $0.lowercased().contains(city.lowercased()) }
            isShowingRecipientCitySuggestions = !filteredRecipientCitySuggestions.isEmpty
        }
    }
    
    private func extractCitiesAndRegions(from address: String) -> [String] {
        let components = address.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        let cityKeywords = ["город", "г", "область", "республика", "край"]
        
        let filteredComponents = components.filter { component in
            return cityKeywords.contains(where: { keyword in
                component.lowercased().contains(keyword)
            })
        }
        
        return filteredComponents
    }
}
