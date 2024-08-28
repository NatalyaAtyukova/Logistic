import SwiftUI
import Firebase
import FirebaseFirestore
import MapKit
import CoreLocation


struct EditOrderView: View {
  @Environment(\.presentationMode) var presentationMode
  @Binding var order: OrderItem?
  @State private var cargoType = ""
  @State private var cargoWeight = ""
  @State private var deliveryDeadline = Date()
  @State private var orderInfo = ""
  @State private var recipientCompany = ""
  @State private var senderAddress = ""
  @State private var recipientAddress = ""
  @State private var driverName = ""
  @State private var status = ""
  
  @State private var senderCoordinate: CLLocationCoordinate2D?
  @State private var recipientCoordinate: CLLocationCoordinate2D?
  @State private var senderSuggestions: [DaDataSuggestion] = []
  @State private var recipientSuggestions: [DaDataSuggestion] = []
  @State private var isShowingSenderSuggestions = false
  @State private var isShowingRecipientSuggestions = false
  
  let cargoTypes = ["Обычный", "Хрупкий", "Опасный"]
  let statuses = ["Новый", "В пути", "Доставлено"]
  
  var alertManager: AlertManager
  
  var body: some View {
      Form {
          Section(header: Text("Информация о заказе")) {
              Picker("Тип груза", selection: $cargoType) {
                  ForEach(cargoTypes, id: \.self) { cargoType in
                      Text(cargoType)
                  }
              }
              .pickerStyle(SegmentedPickerStyle())
              
              TextField("Вес груза", text: $cargoWeight)
              DatePicker("Крайний срок доставки", selection: $deliveryDeadline, displayedComponents: .date)
              TextField("Информация о заказе", text: $orderInfo)
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
          
          Section(header: Text("Дополнительная информация")) {
              TextField("Имя водителя", text: $driverName)
                  .disabled(true)
                  .foregroundColor(.gray)
          }
          
          Section(header: Text("Статус заказа")) {
              Picker("Статус", selection: $status) {
                  ForEach(statuses, id: \.self) { status in
                      Text(status)
                  }
              }
              .pickerStyle(SegmentedPickerStyle())
          }
          
          Section {
              Button(action: {
                  saveChanges(alertManager: alertManager)
                  presentationMode.wrappedValue.dismiss()
              }) {
                  Text("Сохранить изменения")
              }
              .foregroundColor(.blue)
          }
      }
      .navigationBarTitle("Редактировать заказ")
      .onAppear {
          if let currentOrder = order {
              cargoType = currentOrder.cargoType
              cargoWeight = currentOrder.cargoWeight
              deliveryDeadline = currentOrder.deliveryDeadline
              orderInfo = currentOrder.orderInfo
              recipientCompany = currentOrder.recipientCompany
              senderAddress = currentOrder.senderAddress
              recipientAddress = currentOrder.recipientAddress
              driverName = currentOrder.driverName
              status = currentOrder.status
              senderCoordinate = CLLocationCoordinate2D(latitude: currentOrder.senderLatitude, longitude: currentOrder.senderLongitude)
              recipientCoordinate = CLLocationCoordinate2D(latitude: currentOrder.recipientLatitude, longitude: currentOrder.recipientLongitude)
          }
      }
  }
  
  func saveChanges(alertManager: AlertManager) {
      if let currentOrder = order {
          let db = Firestore.firestore()
          let orderRef = db.collection("OrdersList").document(currentOrder.id)
          
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
                  alertManager.showError(message: "Ошибка при обновлении документа: \(error.localizedDescription)")
              } else {
                  alertManager.showSuccess(message: "Документ успешно обновлен")
              }
          }
      }
  }
}

