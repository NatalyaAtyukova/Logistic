import SwiftUI

struct RegisterView: View {
    @StateObject private var viewModel = RegisterViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Выберите роль", selection: $viewModel.selectedRole) {
                    Text("Организация").tag("admin")
                    Text("Водитель").tag("driver")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // Email Field
                VStack(alignment: .leading) {
                    TextField("Почта", text: $viewModel.email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .border(viewModel.emailError != nil ? Color.red : Color.clear, width: 2)
                    
                    if let emailError = viewModel.emailError {
                        Text(emailError)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.leading)
                    }
                }

                // Password Field
                VStack(alignment: .leading) {
                    SecureField("Пароль", text: $viewModel.password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .border(viewModel.passwordError != nil ? Color.red : Color.clear, width: 2)

                    if let passwordError = viewModel.passwordError {
                        Text(passwordError)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.leading)
                    }
                }

                if let generalError = viewModel.generalError {
                    Text(generalError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.leading)
                }

                Button(action: {
                    if viewModel.validateFields() {
                        viewModel.registerNewUser()
                    }
                }) {
                    Text("Зарегистрироваться и продолжить")
                }
                .disabled(viewModel.selectedRole.isEmpty || viewModel.isRegistrationComplete)
                .padding()

                // Условный переход на нужный экран профиля в зависимости от роли
                NavigationLink(
                    destination: viewModel.selectedRole == "admin"
                        ? AnyView(AdminProfileView(userID: viewModel.authUserID ?? "", email: viewModel.email))
                        : AnyView(DriverProfileView(userID: viewModel.authUserID ?? "", email: viewModel.email)),
                    isActive: $viewModel.shouldNavigateToProfile
                ) {
                    EmptyView()
                }
            }
            .navigationBarTitle("Регистрация")
        }
    }
}
