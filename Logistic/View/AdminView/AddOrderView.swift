import SwiftUI
import Firebase
import FirebaseFirestore
import MapKit
import CoreLocation


struct AddOrderView: View {
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var cargoType = ""
    @State private var deliveryDeadline = Date()
    @State private var orderInfo = ""
    @State private var cargoWeight = ""
    @State private var recipientCompany = ""
    @State private var senderAddress = ""
    @State private var recipientAddress = ""
    @State private var selectedCargoType = "Обычный"
    @State private var selectedStatus = "Новый"
    @State private var driverName = "Не нашли водителя"
    
    @State private var senderCoordinate: CLLocationCoordinate2D?
    @State private var recipientCoordinate: CLLocationCoordinate2D?
    @State private var senderSuggestions: [DaDataSuggestion] = []
    @State private var recipientSuggestions: [DaDataSuggestion] = []
    @State private var isShowingSenderSuggestions = false
    @State private var isShowingRecipientSuggestions = false
    
    let cargoTypes = ["Обычный", "Хрупкий", "Опасный"]
    let statuses = ["Новый", "В пути", "Доставлено"]
    
    var currentUser = Auth.auth().currentUser
    var alertManager: AlertManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Информация о заказе")) {
                    Picker("Тип груза", selection: $selectedCargoType) {
                        ForEach(cargoTypes, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    DatePicker("Крайний срок доставки", selection: $deliveryDeadline, displayedComponents: .date)
                    
                    TextField("Информация о заказе", text: $orderInfo)
                    
                    TextField("Вес груза", text: $cargoWeight)
                    
                    TextField("Компания-получатель", text: $recipientCompany)
                }
                
                Section(header: Text("Адреса")) {
                    AddressAutocompleteTextField(
                        title: "Откуда",
                        address: $senderAddress,
                        coordinate: $senderCoordinate,
                        suggestions: $senderSuggestions,
                        isShowingSuggestions: $isShowingSenderSuggestions,
                        onAddressSelected: { suggestion in
                            self.senderAddress = suggestion.value
                            if let lat = Double(suggestion.data.geo_lat ?? ""), let lon = Double(suggestion.data.geo_lon ?? "") {
                                self.senderCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                            } else {
                                print("Invalid coordinates received")
                            }
                            self.isShowingSenderSuggestions = false
                        }
                    )
                    
                    AddressAutocompleteTextField(
                        title: "Куда",
                        address: $recipientAddress,
                        coordinate: $recipientCoordinate,
                        suggestions: $recipientSuggestions,
                        isShowingSuggestions: $isShowingRecipientSuggestions,
                        onAddressSelected: { suggestion in
                            self.recipientAddress = suggestion.value
                            if let lat = Double(suggestion.data.geo_lat ?? ""), let lon = Double(suggestion.data.geo_lon ?? "") {
                                self.recipientCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                            } else {
                                print("Invalid coordinates received")
                            }
                            self.isShowingRecipientSuggestions = false
                        }
                    )
                }
                
                Section(header: Text("Другая информация")) {
                    Picker("Статус", selection: $selectedStatus) {
                        ForEach(statuses, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    TextField("Водитель", text: $driverName)
                        .disabled(true)
                        .foregroundColor(.gray)
                }
                
                Section {
                    Button(action: {
                        addOrder()
                    }) {
                        Text("Добавить заказ")
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationBarTitle("Добавить заказ")
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Заказ добавлен"), message: Text(alertMessage), dismissButton: .default(Text("OK")) {
                    self.presentationMode.wrappedValue.dismiss()
                })
            }
        }
    }
    
    
    func addOrder() {
        let db = Firestore.firestore()
        
        guard let senderCoordinate = senderCoordinate, let recipientCoordinate = recipientCoordinate else {
            alertManager.showError(message: "Необходимо выбрать адрес отправления и получения.")
            return
        }
        
        if let currentUser = currentUser {
            let newOrderId = generateReadableOrderId(for: Date()) // Генерация удобочитаемого id
            
            db.collection("OrdersList").document(newOrderId).setData([
                "id": newOrderId, // Добавляем удобочитаемый id в документ
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
            ]) { error in
                if let error = error {
                    alertManager.showError(message: "Ошибка при добавлении заказа: \(error.localizedDescription)")
                } else {
                    self.alertMessage = "Заказ успешно добавлен!"
                    self.showingAlert = true
                    clearFields()
                }
            }
        } else {
            alertManager.showError(message: "Ошибка: пользователь не авторизован.")
        }
    }

    
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
}

