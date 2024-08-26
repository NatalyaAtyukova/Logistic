import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ResetPasswordView: View {
    @State private var email: String = ""
    @State private var emailError: String? = nil
    @State private var successMessage: String? = nil
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack {
            Text("Сброс пароля")
                .font(.largeTitle)
                .padding()
            
            // Email Field
            VStack(alignment: .leading) {
                TextField("Введите вашу почту", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .border(emailError != nil ? Color.red : Color.clear, width: 2)
                
                if let emailError = emailError {
                    Text(emailError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.leading)
                }
            }
            
            // Success or Error Message
            if let successMessage = successMessage {
                Text(successMessage)
                    .foregroundColor(.green)
                    .font(.caption)
                    .padding()
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }
            
            // Button to reset password
            Button(action: {
                checkEmailExists()
            }) {
                Text("Сбросить пароль")
            }
            .padding()
            
            Spacer()
        }
        .padding()
        .navigationBarTitle("Восстановление пароля", displayMode: .inline)
    }

    // Проверка наличия email в базе данных
    func checkEmailExists() {
        emailError = nil
        successMessage = nil
        errorMessage = nil
        
        // Валидация email
        if !Validation.isValidEmail(email) {
            emailError = "Введите корректный email"
            return
        }
        
        // Обращаемся к базе данных Firestore
        let db = Firestore.firestore()
        
        // Поиск в коллекции AdminProfiles
        let adminRef = db.collection("AdminProfiles").whereField("email", isEqualTo: email)
        adminRef.getDocuments { (snapshot, error) in
            if let error = error {
                errorMessage = "Ошибка при проверке: \(error.localizedDescription)"
                return
            }
            
            if let snapshot = snapshot, !snapshot.isEmpty {
                // Если email найден в AdminProfiles
                resetPassword()
            } else {
                // Если не найден в AdminProfiles, ищем в DriverProfiles
                let driverRef = db.collection("DriverProfiles").whereField("email", isEqualTo: email)
                driverRef.getDocuments { (snapshot, error) in
                    if let error = error {
                        errorMessage = "Ошибка при проверке: \(error.localizedDescription)"
                        return
                    }
                    
                    if let snapshot = snapshot, !snapshot.isEmpty {
                        // Если email найден в DriverProfiles
                        resetPassword()
                    } else {
                        // Если email не найден ни в одной из коллекций
                        errorMessage = "Пользователь с таким email не найден."
                    }
                }
            }
        }
    }

    // Сброс пароля через FirebaseAuth
    func resetPassword() {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                errorMessage = "Ошибка при сбросе пароля: \(error.localizedDescription)"
            } else {
                successMessage = "Инструкция по сбросу пароля отправлена на почту."
            }
        }
    }
}
