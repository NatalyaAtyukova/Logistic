import SwiftUI
import Firebase
import MapKit
import CoreLocation
import FirebaseFirestore

struct FindOrderView: View {
    @State private var senderCity: String = ""
    @State private var recipientCity: String = ""
    @State private var orders: [OrderItem] = []
    @State private var isShowingOrdersList = false
    @State private var senderCitySuggestions: [String] = []
    @State private var recipientCitySuggestions: [String] = []
    @State private var isShowingSenderCitySuggestions = false
    @State private var isShowingRecipientCitySuggestions = false
    
    @ObservedObject var alertManager: AlertManager
    var currentUser = Auth.auth().currentUser
    
    var body: some View {
        NavigationView {
            VStack {
                CityAutocompleteTextField(
                    title: "Город отправления или область",
                    city: $senderCity,
                    suggestions: $senderCitySuggestions,
                    isShowingSuggestions: $isShowingSenderCitySuggestions,
                    onCitySelected: { selectedCity in
                        self.senderCity = selectedCity
                        self.isShowingSenderCitySuggestions = false
                        fetchRecipientCitySuggestions(for: selectedCity)
                    }
                )
                
                CityAutocompleteTextField(
                    title: "Город назначения или область",
                    city: $recipientCity,
                    suggestions: $recipientCitySuggestions,
                    isShowingSuggestions: $isShowingRecipientCitySuggestions,
                    onCitySelected: { selectedCity in
                        self.recipientCity = selectedCity
                        self.isShowingRecipientCitySuggestions = false
                    }
                )
                
                Button(action: {
                    searchOrders()
                }) {
                    Text("Найти заказы")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                
                if let currentUser = currentUser {
                    NavigationLink(destination: FindListView(alertManager: alertManager, currentUser: currentUser, orders: $orders), isActive: $isShowingOrdersList) {
                        EmptyView()
                    }
                    .hidden()
                }
            }
            .padding()
            .navigationBarTitle("Поиск заказов")
            .alert(isPresented: $alertManager.showAlert) {
                Alert(title: Text("Сообщение"),
                      message: Text(alertManager.alertMessage),
                      dismissButton: .default(Text("OK")) {
                    alertManager.showAlert = false
                })
            }
            .onAppear {
                fetchSenderCitySuggestions()
            }
        }
    }
    
    private func searchOrders() {
        let db = Firestore.firestore()
        
        print("Searching for orders with senderCity: \(senderCity) and recipientCity: \(recipientCity)")
        
        db.collection("OrdersList")
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    alertManager.showError(message: "Ошибка при поиске заказов: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    alertManager.showError(message: "Заказы не найдены")
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
                        let status = data["status"] as? String
                    else {
                        return nil
                    }
                    
                    let deliveryDeadline = deliveryDeadlineTimestamp.dateValue()
                    
                    let orderItem = OrderItem(
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
                    
                    let senderCityMatches = senderAddress.lowercased().contains(senderCity.lowercased())
                    let recipientCityMatches = recipientAddress.lowercased().contains(recipientCity.lowercased())
                    
                    return senderCityMatches && recipientCityMatches ? orderItem : nil
                }
                
                print("Found \(orders.count) orders matching criteria")
                
                self.orders = orders
                self.isShowingOrdersList = true
            }
    }
    
    private func fetchSenderCitySuggestions() {
        let db = Firestore.firestore()
        
        db.collection("OrdersList").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching city suggestions: \(error.localizedDescription)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents found for city suggestions")
                return
            }
            
            let senderCities = Set(documents.compactMap { $0.data()["senderAddress"] as? String }.flatMap { extractCitiesAndRegions(from: $0) })
            
            self.senderCitySuggestions = Array(senderCities)
        }
    }
    
    private func fetchRecipientCitySuggestions(for senderCity: String) {
        let db = Firestore.firestore()
        
        db.collection("OrdersList")
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching recipient city suggestions: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No documents found for recipient city suggestions")
                    return
                }
                
                let recipientCities = Set(documents.compactMap { $0.data()["recipientAddress"] as? String }.flatMap { extractCitiesAndRegions(from: $0) })
                
                self.recipientCitySuggestions = Array(recipientCities)
            }
    }
    
    private func extractCitiesAndRegions(from address: String) -> [String] {
        let components = address.split(separator: ",")
        return components.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}
