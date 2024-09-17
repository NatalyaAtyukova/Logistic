import SwiftUI
import Firebase

class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLogged: Bool = false
    @Published var userRole: String = ""
    @Published var selectedView: AnyView? = nil
    @Published var showResetPassword: Bool = false

    init() {
        checkIfLogged()
    }

    // Проверка статуса авторизации при запуске
    func checkIfLogged() {
        if UserDefaults.standard.bool(forKey: "isLogged") {
            self.isLogged = true
            let userId = UserDefaults.standard.string(forKey: "userId") ?? ""
            let role = UserDefaults.standard.string(forKey: "userRole") ?? ""

            if role == "admin" {
                self.selectedView = AnyView(AdminTabView(userID: userId))
            } else if role == "driver" {
                self.selectedView = AnyView(DriverTabView(userID: userId))
            }
        }
    }

    // Функция для входа
    func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Ошибка входа в систему: \(error.localizedDescription)")
            } else {
                guard let user = result?.user else {
                    print("Ошибка: UID пользователя не найден")
                    return
                }
                let userId = user.uid
                print("UID текущего пользователя: \(userId)")

                let db = Firestore.firestore()
                let adminProfileRef = db.collection("AdminProfiles").document(userId)
                let driverProfileRef = db.collection("DriverProfiles").document(userId)

                adminProfileRef.getDocument { adminDocument, adminError in
                    if let adminDocument = adminDocument, adminDocument.exists {
                        self.userRole = "admin"
                        print("Роль пользователя: админ")

                        UserDefaults.standard.set(true, forKey: "isLogged")
                        UserDefaults.standard.set(userId, forKey: "userId")
                        UserDefaults.standard.set("admin", forKey: "userRole")

                        DispatchQueue.main.async {
                            self.isLogged = true
                            self.selectedView = AnyView(AdminTabView(userID: userId))
                        }
                    } else {
                        driverProfileRef.getDocument { driverDocument, driverError in
                            if let driverDocument = driverDocument, driverDocument.exists {
                                self.userRole = "driver"
                                print("Роль пользователя: водитель")

                                UserDefaults.standard.set(true, forKey: "isLogged")
                                UserDefaults.standard.set(userId, forKey: "userId")
                                UserDefaults.standard.set("driver", forKey: "userRole")

                                DispatchQueue.main.async {
                                    self.isLogged = true
                                    self.selectedView = AnyView(DriverTabView(userID: userId))
                                }
                            } else {
                                print("Данные профиля пользователя не найдены")
                            }
                        }
                    }
                }
            }
        }
    }
}
