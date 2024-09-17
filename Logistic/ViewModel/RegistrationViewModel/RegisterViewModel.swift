import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

class RegisterViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var selectedRole: String = ""
    @Published var isRegistrationComplete: Bool = false
    @Published var authUserID: String? = nil
    @Published var shouldNavigateToProfile: Bool = false

    // Ошибки валидации
    @Published var emailError: String? = nil
    @Published var passwordError: String? = nil
    @Published var generalError: String? = nil

    // Валидация полей
    func validateFields() -> Bool {
        emailError = nil
        passwordError = nil
        generalError = nil

        var isValid = true

        if !Validation.isValidEmail(email) {
            emailError = "Неверный формат email"
            isValid = false
        }

        if !Validation.isValidPassword(password) {
            passwordError = "Пароль должен быть не менее 6 символов"
            isValid = false
        }

        if selectedRole.isEmpty {
            generalError = "Выберите роль"
            isValid = false
        }

        return isValid
    }

    // Регистрация нового пользователя
    func registerNewUser() {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.generalError = "Ошибка при регистрации: \(error.localizedDescription)"
                return
            }

            if let user = authResult?.user {
                self.authUserID = user.uid
                let db = Firestore.firestore()
                let userData = [
                    "email": user.email ?? "",
                    "role": self.selectedRole
                ]

                // Определяем коллекцию в зависимости от роли
                let collection = self.selectedRole == "admin" ? "AdminProfiles" : "DriverProfiles"

                // Сохранение данных пользователя
                db.collection(collection).document(user.uid).setData(userData) { error in
                    if let error = error {
                        self.generalError = "Ошибка при сохранении данных: \(error.localizedDescription)"
                    } else {
                        DispatchQueue.main.async {
                            self.isRegistrationComplete = true
                            self.shouldNavigateToProfile = true
                        }
                    }
                }
            }
        }
    }
}
