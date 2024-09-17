import SwiftUI

struct AdminProfileView: View {
    @StateObject private var viewModel: AdminProfileViewModel

    @Environment(\.presentationMode) var presentationMode

    init(userID: String, email: String) {
        _viewModel = StateObject(wrappedValue: AdminProfileViewModel(userID: userID, email: email))
    }

    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                TextField("Наименование организации", text: $viewModel.nameOrganisation)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .border(viewModel.nameError != nil ? Color.red : Color.clear, width: 2)
                if let nameError = viewModel.nameError {
                    Text(nameError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.leading)
                }
            }

            VStack(alignment: .leading) {
                TextField("ИНН", text: $viewModel.innOrganisation)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .keyboardType(.numberPad)
                    .onChange(of: viewModel.innOrganisation) { _ in
                        viewModel.limitTextFieldInput()
                    }
                    .border(viewModel.innError != nil ? Color.red : Color.clear, width: 2)
                if let innError = viewModel.innError {
                    Text(innError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.leading)
                }
            }

            VStack(alignment: .leading) {
                TextField("Адрес", text: $viewModel.addressOrganisation)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .border(viewModel.addressError != nil ? Color.red : Color.clear, width: 2)
                if let addressError = viewModel.addressError {
                    Text(addressError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.leading)
                }
            }

            VStack(alignment: .leading) {
                TextField("Телефон", text: $viewModel.phoneNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .keyboardType(.phonePad)
                    .onChange(of: viewModel.phoneNumber) { _ in
                        viewModel.limitTextFieldInput()
                    }
                    .border(viewModel.phoneError != nil ? Color.red : Color.clear, width: 2)
                if let phoneError = viewModel.phoneError {
                    Text(phoneError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.leading)
                }
            }

            Button(action: {
                if viewModel.validateFields() {
                    viewModel.saveProfile()
                } else {
                    print("Заполните все поля корректно")
                }
            }) {
                Text("Сохранить профиль")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()

            NavigationLink(destination: AdminTabView(userID: viewModel.userID), isActive: $viewModel.navigateToAdminTab) {
                EmptyView()
            }
        }
        .navigationTitle("Профиль Администратора")
        .onDisappear {
            if viewModel.profileSaved {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
