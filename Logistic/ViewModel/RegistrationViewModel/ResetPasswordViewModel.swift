import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class ResetPasswordViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var emailError: String? = nil
    @Published var successMessage: String? = nil
    @Published var errorMessage: String? = nil

    // Валидация и сброс пароля
    func checkEmailExists() {
        emailError = nil
        successMessage = nil
        errorMessage = nil
        
        // Валидация email
        if !Validation.isValidEmail(email) {
            emailError = "Введите корректный email"
            return
        }
        
        let db = Firestore.firestore()
        
        // Поиск в коллекции AdminProfiles
        let adminRef = db.collection("AdminProfiles").whereField("email", isEqualTo: email)
        adminRef.getDocuments { (snapshot, error) in
            if let error = error {
                self.errorMessage = "Ошибка при проверке: \(error.localizedDescription)"
                return
            }
            
            if let snapshot = snapshot, !snapshot.isEmpty {
                // Если email найден в AdminProfiles
                self.resetPassword()
            } else {
                // Если не найден в AdminProfiles, ищем в DriverProfiles
                let driverRef = db.collection("DriverProfiles").whereField("email", isEqualTo: self.email)
                driverRef.getDocuments { (snapshot, error) in
                    if let error = error {
                        self.errorMessage = "Ошибка при проверке: \(error.localizedDescription)"
                        return
                    }
                    
                    if let snapshot = snapshot, !snapshot.isEmpty {
                        // Если email найден в DriverProfiles
                        self.resetPassword()
                    } else {
                        // Если email не найден ни в одной из коллекций
                        self.errorMessage = "Пользователь с таким email не найден."
                    }
                }
            }
        }
    }

    // Сброс пароля через FirebaseAuth
    private func resetPassword() {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                self.errorMessage = "Ошибка при сбросе пароля: \(error.localizedDescription)"
            } else {
                self.successMessage = "Инструкция по сбросу пароля отправлена на почту."
            }
        }
    }
}
