import SwiftUI
import FirebaseAuth
import Firebase

struct FindOrderView: View {
    @StateObject private var viewModel = FindOrderViewModel()
    @ObservedObject var alertManager: AlertManager
    
    var body: some View {
        NavigationView {
            VStack {
                // Поле для ввода города отправления
                CityAutocompleteTextField(
                    title: "Город отправления, область или край",
                    city: $viewModel.senderCity,
                    suggestions: $viewModel.filteredSenderCitySuggestions,
                    isShowingSuggestions: $viewModel.isShowingSenderCitySuggestions,
                    onCitySelected: { selectedCity in
                        viewModel.senderCity = selectedCity
                        viewModel.isShowingSenderCitySuggestions = false
                    }
                )
                
                // Поле для ввода города назначения
                CityAutocompleteTextField(
                    title: "Город назначения, область или край",
                    city: $viewModel.recipientCity,
                    suggestions: $viewModel.filteredRecipientCitySuggestions,
                    isShowingSuggestions: $viewModel.isShowingRecipientCitySuggestions,
                    onCitySelected: { selectedCity in
                        viewModel.recipientCity = selectedCity
                        viewModel.isShowingRecipientCitySuggestions = false
                    }
                )
                
                Button(action: {
                    viewModel.searchOrders()
                }) {
                    Text("Найти заказы")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                
                if let currentUser = Auth.auth().currentUser {
                    NavigationLink(destination: FindListView(alertManager: alertManager, currentUser: currentUser, orders: $viewModel.orders), isActive: $viewModel.isShowingOrdersList) {
                        EmptyView()
                    }
                    .hidden()
                }
            }
            .padding()
            .navigationBarTitle("Поиск заказов")
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Сообщение"),
                      message: Text(viewModel.alertMessage),
                      dismissButton: .default(Text("OK")))
            }
        }
    }
}
