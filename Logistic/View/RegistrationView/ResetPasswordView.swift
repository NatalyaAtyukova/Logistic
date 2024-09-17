import SwiftUI

struct ResetPasswordView: View {
    @StateObject private var viewModel = ResetPasswordViewModel()
    
    var body: some View {
        VStack {
            Text("Сброс пароля")
                .font(.largeTitle)
                .padding()
            
            // Email Field
            VStack(alignment: .leading) {
                TextField("Введите вашу почту", text: $viewModel.email)
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
            
            // Success or Error Message
            if let successMessage = viewModel.successMessage {
                Text(successMessage)
                    .foregroundColor(.green)
                    .font(.caption)
                    .padding()
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }
            
            // Button to reset password
            Button(action: {
                viewModel.checkEmailExists()
            }) {
                Text("Сбросить пароль")
            }
            .padding()
            
            Spacer()
        }
        .padding()
        .navigationBarTitle("Восстановление пароля", displayMode: .inline)
    }
}
