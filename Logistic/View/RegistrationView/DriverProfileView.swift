import SwiftUI

struct DriverProfileView: View {
    @StateObject private var viewModel: DriverProfileViewModel

    @Environment(\.presentationMode) var presentationMode

    init(userID: String, email: String) {
        _viewModel = StateObject(wrappedValue: DriverProfileViewModel(userID: userID, email: email))
    }

    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                TextField("Имя", text: $viewModel.firstName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .border(viewModel.firstNameError != nil ? Color.red : Color.clear, width: 2)
                if let firstNameError = viewModel.firstNameError {
                    Text(firstNameError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.leading)
                }
            }

            VStack(alignment: .leading) {
                TextField("Фамилия", text: $viewModel.lastName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .border(viewModel.lastNameError != nil ? Color.red : Color.clear, width: 2)
                if let lastNameError = viewModel.lastNameError {
                    Text(lastNameError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.leading)
                }
            }

            VStack(alignment: .leading) {
                TextField("Номер водительского удостоверения", text: $viewModel.licenseNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .keyboardType(.numberPad)
                    .onChange(of: viewModel.licenseNumber) { _ in
                        viewModel.limitTextFieldInput()
                    }
                    .border(viewModel.licenseError != nil ? Color.red : Color.clear, width: 2)
                if let licenseError = viewModel.licenseError {
                    Text(licenseError)
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
            }
            .padding()

            NavigationLink(destination: DriverTabView(userID: viewModel.userID), isActive: $viewModel.navigateToDriverTab) {
                EmptyView()
            }
        }
        .navigationTitle("Профиль Водителя")
        .onDisappear {
            if viewModel.profileSaved {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
