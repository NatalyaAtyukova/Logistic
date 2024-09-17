import SwiftUI
import Firebase
import FirebaseFirestore
import CoreLocation

struct EditOrderView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: EditOrderViewModel

    // Изменяем параметр order на Binding
    init(order: Binding<OrderItem>, alertManager: AlertManager) {
        _viewModel = StateObject(wrappedValue: EditOrderViewModel(order: order.wrappedValue, alertManager: alertManager))
    }

    var body: some View {
        Form {
            Section(header: Text("Информация о заказе")) {
                Picker("Тип груза", selection: $viewModel.cargoType) {
                    ForEach(viewModel.cargoTypes, id: \.self) { cargoType in
                        Text(cargoType)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                TextField("Вес груза", text: $viewModel.cargoWeight)
                DatePicker("Крайний срок доставки", selection: $viewModel.deliveryDeadline, displayedComponents: .date)
                TextField("Информация о заказе", text: $viewModel.orderInfo)
                TextField("Компания-получатель", text: $viewModel.recipientCompany)
            }
            
            Section(header: Text("Адреса")) {
                AddressAutocompleteTextField(
                    title: "Откуда",
                    address: $viewModel.senderAddress,
                    coordinate: $viewModel.senderCoordinate,
                    suggestions: $viewModel.senderSuggestions,
                    isShowingSuggestions: $viewModel.isShowingSenderSuggestions,
                    onAddressSelected: { suggestion in
                        viewModel.senderAddress = suggestion.value
                        if let lat = Double(suggestion.data.geo_lat ?? ""), let lon = Double(suggestion.data.geo_lon ?? "") {
                            viewModel.senderCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        }
                        viewModel.isShowingSenderSuggestions = false
                    }
                )
                
                AddressAutocompleteTextField(
                    title: "Куда",
                    address: $viewModel.recipientAddress,
                    coordinate: $viewModel.recipientCoordinate,
                    suggestions: $viewModel.recipientSuggestions,
                    isShowingSuggestions: $viewModel.isShowingRecipientSuggestions,
                    onAddressSelected: { suggestion in
                        viewModel.recipientAddress = suggestion.value
                        if let lat = Double(suggestion.data.geo_lat ?? ""), let lon = Double(suggestion.data.geo_lon ?? "") {
                            viewModel.recipientCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        }
                        viewModel.isShowingRecipientSuggestions = false
                    }
                )
            }
            
            Section(header: Text("Дополнительная информация")) {
                TextField("Имя водителя", text: $viewModel.driverName)
                    .disabled(true)
                    .foregroundColor(.gray)
            }
            
            Section(header: Text("Статус заказа")) {
                Picker("Статус", selection: $viewModel.status) {
                    ForEach(viewModel.statuses, id: \.self) { status in
                        Text(status)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section {
                Button(action: {
                    viewModel.saveChanges()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Сохранить изменения")
                }
                .foregroundColor(.blue)
            }
        }
        .navigationBarTitle("Редактировать заказ")
        .alert(isPresented: $viewModel.showingAlert) {
            Alert(title: Text("Изменения сохранены"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}
