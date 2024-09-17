import SwiftUI
import CoreLocation

struct AddOrderView: View {
    
    @StateObject private var viewModel: AddOrderViewModel

    @Environment(\.presentationMode) var presentationMode
    
    // Инициализируем ViewModel внутри View
      init(alertManager: AlertManager) {
          _viewModel = StateObject(wrappedValue: AddOrderViewModel(alertManager: alertManager))
      }


    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Информация о заказе")) {
                    Picker("Тип груза", selection: $viewModel.selectedCargoType) {
                        ForEach(viewModel.cargoTypes, id: \.self) {
                            Text($0)
                        }
                    }

                    DatePicker("Крайний срок доставки", selection: $viewModel.deliveryDeadline, displayedComponents: .date)

                    TextField("Информация о заказе", text: $viewModel.orderInfo)

                    TextField("Вес груза", text: $viewModel.cargoWeight)

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

                Section(header: Text("Другая информация")) {
                    Picker("Статус", selection: $viewModel.selectedStatus) {
                        ForEach(viewModel.statuses, id: \.self) {
                            Text($0)
                        }
                    }

                    TextField("Водитель", text: $viewModel.driverName)
                        .disabled(true)
                        .foregroundColor(.gray)
                }

                Section {
                    Button(action: {
                        viewModel.addOrder()
                    }) {
                        Text("Добавить заказ")
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationBarTitle("Добавить заказ")
            .alert(isPresented: $viewModel.showingAlert) {
                Alert(title: Text("Заказ добавлен"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")) {
                    self.presentationMode.wrappedValue.dismiss()
                })
            }
        }
    }
}
